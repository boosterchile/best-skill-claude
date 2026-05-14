# Benchmark — Compliance Telemetry

> Lo que no se mide, no mejora. Este sistema mide si el ciclo agent-rigor está siendo respetado, y compara la sesión actual contra una baseline.

## Qué mide

El benchmark lee los **session ledgers** (`.claude/ledger/*.jsonl`) y produce métricas accionables. No mide "calidad del código" (eso lo hace `/review`), mide **compliance con el ciclo**.

### Métricas principales

| Métrica | Definición | Buena dirección |
|---|---|---|
| **Spec-before-code rate** | % de features donde `spec.md` existe antes del primer commit en código fuente | ↑ acercándose a 100% |
| **TDD compliance** | % de archivos test que aparecen antes que el archivo de implementación que prueban | ↑ acercándose a 100% para código nuevo |
| **Commit size** | LOC promedio por commit | ↓ acercándose a ≤100 |
| **Review-before-merge rate** | % de commits a `main` con `.specs/<feature>/review.md` previo | 100% (no negociable) |
| **Devils-advocate invocation rate** | % de transiciones a REVIEW/SHIP con invocación del sub-agente | 100% en solo-dev |
| **ADR coverage** | % de decisiones arquitectónicas que tienen ADR en `docs/adr/` | ↑ |
| **Drift-blocked rate** | drift_blocked events / drift_detected events | Alto blocked, bajo justified |
| **Skip-cycle rate** | % de acciones declaradas `[skip-cycle]` | ↓ bajo 20% |
| **Cooling-off respect rate** | % de `/review` con ≥ 30 min desde último write de source | 100% (waivers contados aparte) |
| **Phase-artifact completeness** | % de fases con su artefacto esperado en disco | ↑ acercándose a 100% |

### Métricas secundarias (signal, no score)

- Tiempo promedio por fase
- Distribución de tipos de drift más frecuentes
- Top-3 skills más leídas / menos leídas
- Sub-agentes invocados por sesión
- Frecuencia de waivers

## Cómo correrlo

### Self-check (verificar instalación)

```bash
bash benchmark/scripts/collect-metrics.sh --self-check
```

Verifica que `jq`, `git`, hooks ejecutables, skills presentes, directorios escribibles.

### Score de la última sesión

```bash
bash benchmark/scripts/score-session.sh --last
```

### Score de un rango de tiempo

```bash
bash benchmark/scripts/score-session.sh --since "7 days ago"
bash benchmark/scripts/score-session.sh --since "2026-05-01" --until "2026-05-13"
```

### Comparación contra baseline

```bash
bash benchmark/scripts/compare-to-baseline.sh --since "7 days ago"
```

Imprime el scorecard con flechas `↑ ↓ =` versus `benchmark/baseline.json`.

## La baseline

`benchmark/baseline.json` contiene los valores de referencia. Vienen pre-cargados con valores conservadores derivados de un proyecto solo-dev típico **sin** agent-rigor (baseline negativa) y los **targets** con agent-rigor.

```json
{
  "version": 1,
  "captured_on": "2026-05-13",
  "without_agent_rigor": {
    "spec_before_code_rate": 0.20,
    "tdd_compliance": 0.15,
    "commits_le_100_loc": 0.55,
    "review_before_merge_rate": 0.40,
    "devils_advocate_rate": 0.0,
    "adr_coverage": 0.10,
    "skip_cycle_rate": 0.45,
    "cooling_off_respect_rate": 0.0
  },
  "target_with_agent_rigor": {
    "spec_before_code_rate": 0.95,
    "tdd_compliance": 0.80,
    "commits_le_100_loc": 0.90,
    "review_before_merge_rate": 1.00,
    "devils_advocate_rate": 1.00,
    "adr_coverage": 0.80,
    "skip_cycle_rate": 0.15,
    "cooling_off_respect_rate": 0.95
  }
}
```

Tu propia baseline se captura corriendo `score-session.sh --capture-baseline --since "30 days ago"`. Útil tras tres meses para tener referencia personal.

## El scorecard

Después de `score-session.sh` ves algo así:

```
agent-rigor — Scorecard (2026-05-06 → 2026-05-13)

Compliance:
  Spec antes de código:          8/9   89%    (target 95%) ⚠
  TDD (test antes de impl):      6/9   67%    (target 80%) ⚠
  Commits ≤100 LOC:             22/24  92%    (target 90%) ✓
  Review pre-merge:              9/9  100%    (target 100%) ✓
  Devils-advocate invocado:      9/9  100%    (target 100%) ✓
  ADR para decisiones nuevas:    3/4   75%    (target 80%) =
  Cooling-off respetado:         7/9   78%    (target 95%) ⚠
  Skip-cycle rate:                12%    (cap 20%) ✓

Drift:
  drift_detected:   12  (user_prompt: 7, tool_input: 5)
  drift_blocked:     4
  drift_justified:   8  (top: "for now"×4, "MVP"×2, "quick fix"×2)

Top skills leídas:
  11-spec-driven-development     (12 reads)
  31-test-driven-development     (9 reads)
  50-code-review-and-quality     (9 reads)

Skills NO leídas en este período:
  52-security-and-hardening
  62-deprecation-and-migration
  53-performance-optimization

Sugerencias accionables:
  - 2 cooling-off respetados con waiver. Revisar: ledger 2026-05-08, 2026-05-11.
  - "MVP" usado 2 veces sin justificación robusta. Revisar contexto.
  - 0 lecturas de security-and-hardening: si tocaste auth/input/red este mes,
    `/review` debería haber leído este skill.
```

## Cómo se almacenan los datos

- **Source**: `.claude/ledger/*.jsonl` (versionado con `.gitignore` por defecto; tú decides si commitear)
- **Derived**: `benchmark/data/` (autogenerado, gitignored siempre)
- **Reports**: `benchmark/reports/<YYYY-MM-DD>_scorecard.md` (commiteables si quieres histórico)

## Privacidad

El ledger contiene paths absolutos, nombres de feature, y hashes de archivos. **No contiene contenido de archivos** ni datos de usuario. Es seguro commitear en repos privados; revisar antes de commitear en repos públicos.

## Integración con CI

Si corres CI, agregar:

```yaml
- name: agent-rigor scorecard
  run: bash benchmark/scripts/score-session.sh --since "1 day ago" --format json > scorecard.json
- uses: actions/upload-artifact@v4
  with:
    name: agent-rigor-scorecard
    path: scorecard.json
```

Útil para detectar drift en CI semanal sin involucrar dashboards externos.
