# agent-rigor

**Disciplina de ingeniería senior para agentes de código, con compuertas duras de cumplimiento.**

Fork derivado y endurecido de [`addyosmani/agent-skills`](https://github.com/addyosmani/agent-skills), con el motor de razonamiento UI/UX de [`nextlevelbuilder/ui-ux-pro-max-skill`](https://github.com/nextlevelbuilder/ui-ux-pro-max-skill) integrado, y una capa propia de _forcing functions_, telemetría y adaptación para desarrollador solo en macOS.

```
  DEFINE          PLAN           BUILD          VERIFY         REVIEW          SHIP
 ┌──────┐      ┌──────┐      ┌──────┐      ┌──────┐      ┌──────┐      ┌──────┐
 │ Idea │ ───▶ │ Spec │ ───▶ │ Code │ ───▶ │ Test │ ───▶ │  QA  │ ───▶ │  Go  │
 │Refine│      │  PRD │      │ Impl │      │Debug │      │ Gate │      │ Live │
 └──────┘      └──────┘      └──────┘      └──────┘      └──────┘      └──────┘
  /spec          /plan          /build        /test         /review       /ship
                                  │
                                  └─── /design (UI/UX)
                                            ▲
                                  design-system/MASTER.md
                                  design-system/pages/*.md
```

## Qué es distinto

Frente al pack upstream de Addy Osmani:

| Capa | upstream | agent-rigor |
|---|---|---|
| Skills | 20 archivos Markdown que el agente *puede* leer | Las mismas 20 + UI/UX, declaradas como **contratos**: si no se cumplen, el hook bloquea |
| Anti-racionalización | Tabla pasiva | **Hook `PreToolUse`** que intercepta lenguaje de atajo ("for now", "MVP", "later") y exige justificación |
| Orden del ciclo | Sugerido por documentación | **Forzado**: no se permite `Write`/`Edit` sin `.specs/<feature>/spec.md` previo |
| Memoria entre sesiones | Ninguna | **Session ledger** en `.claude/ledger/<id>.jsonl` que persiste decisiones, skips y justificaciones |
| Revisión en solo | Asume otro humano | **Devil's-advocate sub-agent** + cooling-off obligatorio o waiver explícito |
| Métricas | Ninguna | **Benchmark** con scorecard semanal: compliance TDD, tamaño de commit, gap spec→code, gap test→prod |
| UI/UX | Skill genérica | Skill `design-system-generation` con artefactos `MASTER.md` + page overrides versionados |
| Plataforma | Asume Linux | **Optimizado para macOS** (bash 3.2 compatible, BSD utils, `osascript` para notificaciones) |

## Filosofía

> El agente quiere agradarte. Tomar atajos lo hace eficiente y "útil". Tu trabajo es darle un entorno donde el atajo cueste más que el camino correcto.

Cinco principios:

1. **Las skills son contratos**, no sugerencias. La diferencia está en los hooks.
2. **El ciclo es no-negociable**: Define → Plan → Build → Verify → Review → Ship. Saltarse fases requiere waiver explícito y queda en el ledger.
3. **Lo que no se mide no mejora**. El benchmark corre cada vez que cierras una sesión.
4. **Solo ≠ relajado**. En un equipo tienes pares que objetan. Solo, ese rol lo cubre `devils-advocate` + el cooling-off.
5. **macOS de primera clase**. Nada de "funciona en Linux, en tu Mac veremos". Bash 3.2, BSD `sed`/`date`, paths con espacios, ARM y x86.

## Instalación

### Requisitos

- macOS 14+ (probado en Sonoma y Sequoia)
- Bash 3.2 (el que viene con macOS) o superior — los hooks son compatibles con 3.2
- Claude Code instalado (`brew install --cask claude-code` o vía instalador oficial)
- `jq` para procesar el ledger (`brew install jq`)
- Opcional: `gh` para integraciones de PR (`brew install gh`)

### Instalación como plugin de Claude Code

```bash
# 'best-skill-claude' es el repo, 'agent-rigor' es el nombre interno del marketplace y del plugin
/plugin marketplace add fueradelabox/best-skill-claude
/plugin install agent-rigor@agent-rigor
```

### Instalación manual (desarrollo local)

```bash
git clone https://github.com/fueradelabox/best-skill-claude.git ~/.claude/plugins/agent-rigor
# Habilitar hooks a nivel de usuario:
cp ~/.claude/plugins/agent-rigor/.claude/settings.json ~/.claude/settings.json
# O por proyecto:
cd /tu/proyecto
cp -r ~/.claude/plugins/agent-rigor/.claude .
```

### Verificación post-instalación

```bash
bash ~/.claude/plugins/agent-rigor/benchmark/scripts/collect-metrics.sh --self-check
```

Debe imprimir `✓ hooks OK`, `✓ skills OK`, `✓ ledger writable`, `✓ jq present`.

## Comandos

| Comando | Fase | Qué hace |
|---|---|---|
| `/spec` | Define | Produce `.specs/<feature>/spec.md` con PRD completo. Bloquea avance sin él. |
| `/plan` | Plan | Descompone spec en tareas atómicas en `.specs/<feature>/plan.md` |
| `/build` | Build | Implementación incremental, una rebanada vertical a la vez |
| `/design` | Build | Genera `design-system/MASTER.md` o `pages/<page>.md` (UI/UX) |
| `/test` | Verify | TDD + integración + browser testing si aplica |
| `/review` | Review | Auto-revisión de cinco ejes + invocación de `devils-advocate` |
| `/code-simplify` | Review | Reducir complejidad manteniendo comportamiento exacto |
| `/ship` | Ship | Checklist de lanzamiento + feature flags + monitoreo |
| `/benchmark` | Meta | Genera scorecard de la sesión y compara con baseline |

## Las 22 skills

Las **20 originales de Addy Osmani** se mantienen íntegras (con mejoras de cumplimiento y adaptación solo-developer) y se agregan dos:

- **`00-using-this-pack`** — Meta-skill que explica el contrato, los hooks y el ledger. Es la primera lectura obligatoria de cada sesión.
- **`35-design-system-generation`** — Motor de razonamiento UI/UX adaptado del trabajo de `nextlevelbuilder`. Genera el sistema de diseño completo (patrón + estilo + paleta + tipografía + efectos + anti-patrones + checklist de pre-entrega) y lo persiste en `design-system/`.

Ver el directorio `skills/` para el listado completo. Cada skill sigue la anatomía:

```
SKILL.md
  Frontmatter (name, description, when-to-use, requires, produces)
  Overview
  When to Use
  Process (pasos numerados con compuertas)
  Rationalizations (excusas + refutaciones)
  Red Flags (señales de que algo va mal)
  Verification (evidencia requerida, no opcional)
  Solo-Developer Adaptation (cómo aplica si trabajas solo)
  macOS Notes (comandos/herramientas específicas)
```

## Benchmark

Cada sesión que termina escribe métricas a `benchmark/data/<fecha>.jsonl`. Después de la primera semana corres:

```bash
bash benchmark/scripts/score-session.sh --since "7 days ago"
```

Y obtienes un scorecard como:

```
agent-rigor — Weekly Scorecard (2026-05-06 → 2026-05-13)

Compliance:
  Spec antes de código:         8/9   (89%)   ↑ +12 vs baseline
  TDD (test antes de impl):     6/9   (67%)   ↑ +25 vs baseline
  Commits ≤100 LOC:            22/24  (92%)   ↑ +8  vs baseline
  Review ejecutado pre-merge:  9/9   (100%)  =   vs baseline
  ADR para decisiones nuevas:   3/4   (75%)   ↑ +50 vs baseline

Drift detectado (palabras gatillo bloqueadas):
  "for now"           4 veces (justificadas: 4)
  "MVP"               1 vez   (justificadas: 0)  ⚠
  "quick fix"         2 veces (justificadas: 2)

Sugerencias:
  - 1 ocurrencia de "MVP" sin justificación. Revisa ledger 2026-05-11.
  - Compliance TDD bajo en proyecto "X". Considera /test antes de /build.
```

## Documentación

- [`docs/getting-started.md`](docs/getting-started.md) — Primera sesión paso a paso
- [`docs/anti-drift.md`](docs/anti-drift.md) — Cómo funcionan los hooks y el ledger
- [`docs/solo-developer.md`](docs/solo-developer.md) — Adaptaciones cuando trabajas solo
- [`docs/macos-setup.md`](docs/macos-setup.md) — Tooling y troubleshooting macOS
- [`docs/benchmark.md`](docs/benchmark.md) — Cómo leer e interpretar el scorecard

## Atribuciones

Este proyecto incorpora trabajo derivado de:

- **[`addyosmani/agent-skills`](https://github.com/addyosmani/agent-skills)** (MIT) — estructura de skills, anti-rationalization tables, ciclo de vida, referencias base
- **[`nextlevelbuilder/ui-ux-pro-max-skill`](https://github.com/nextlevelbuilder/ui-ux-pro-max-skill)** (MIT) — motor de razonamiento UI/UX, patrón MASTER+overrides, checklist pre-entrega

Ver [`ATTRIBUTION.md`](ATTRIBUTION.md) para el detalle archivo por archivo.

## Contribuir

Las contribuciones deben **agregar disciplina, no removerla**. Cualquier PR que afloje una compuerta requiere justificación explícita en el cuerpo del PR. Ver [`CONTRIBUTING.md`](CONTRIBUTING.md).

## Licencia

MIT. Ver [`LICENSE`](LICENSE).
