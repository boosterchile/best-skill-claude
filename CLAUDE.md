# CLAUDE.md — Operating Contract

> **Este archivo es un contrato vinculante para el agente, no documentación opcional.**
> Antes de cualquier acción no-trivial (cualquier `Write`, `Edit`, `Bash` que modifique el sistema, o transición de fase) el agente DEBE haber leído este archivo en la sesión actual.
> El hook `SessionStart` verifica que esta lectura ocurrió. Si no ocurrió, el primer `Write`/`Edit` será bloqueado por `PreToolUse`.

---

## 1. La regla de oro

> **El usuario es un desarrollador senior trabajando solo. No produce MVPs. No acepta deuda técnica deliberada. El ciclo de vida completo aplica a todo cambio que toque más de un archivo o cualquier código que termine en `main`.**

Esto significa, sin excepciones:

- Spec antes de código
- Plan antes de implementación
- Test antes de comportamiento
- Review antes de merge
- ADR antes de decisiones arquitectónicas
- Documentación antes de cerrar

Si el cambio es genuinamente trivial (typo en un comentario, ajuste de variable de entorno, formateo), declararlo explícitamente como `[skip-cycle: <razón>]` en el primer mensaje del agente. Eso se registra en el ledger y se cuenta en el benchmark. Si el agente declara `skip-cycle` para más del 20% de las acciones de la semana, el benchmark lo marca como _drift_.

---

## 2. El ciclo no-negociable

```
DEFINE   →   PLAN   →   BUILD   →   VERIFY   →   REVIEW   →   SHIP
 /spec     /plan      /build       /test       /review      /ship
                        │
                        └─ /design (si toca UI/UX)
```

**Reglas de transición:**

- Cada fase produce un **artefacto persistente** en `.specs/<feature>/`. Sin artefacto no hay transición.
- La transición la **propone el agente, la confirma el humano**. Nunca automática.
- Saltar fases requiere `[skip-cycle: <razón>]` y queda en el ledger.
- Volver atrás en el ciclo (ej: de BUILD a SPEC) es **fomentado**, no penalizado. Lo penalizado es _avanzar sin completar_.

**Artefactos esperados por fase:**

| Fase | Artefacto | Ubicación |
|---|---|---|
| DEFINE | `spec.md` (PRD) | `.specs/<feature>/spec.md` |
| PLAN | `plan.md` (tareas atómicas) | `.specs/<feature>/plan.md` |
| BUILD | Código + diff atómico (~100 LOC) | commit en rama feature |
| BUILD UI/UX | `MASTER.md` y/o `pages/<page>.md` | `design-system/` |
| VERIFY | Salida de tests + cobertura | `.specs/<feature>/verify.md` |
| REVIEW | Auto-revisión + devils-advocate output | `.specs/<feature>/review.md` |
| SHIP | Checklist firmada + ADR si aplica | `.specs/<feature>/ship.md`, `docs/adr/NNNN-*.md` |

---

## 3. Skills activas y cómo invocarlas

Las skills están en `skills/`. Cada slash command activa un subconjunto:

| Comando | Skills que activa |
|---|---|
| `/spec` | `10-idea-refine`, `11-spec-driven-development` |
| `/plan` | `20-planning-and-task-breakdown` |
| `/build` | `30-incremental-implementation`, `32-context-engineering`, `33-source-driven-development`, `34-frontend-ui-engineering`, `36-api-and-interface-design` |
| `/design` | `35-design-system-generation`, `34-frontend-ui-engineering` |
| `/test` | `31-test-driven-development`, `40-browser-testing-with-devtools`, `41-debugging-and-error-recovery` |
| `/review` | `50-code-review-and-quality`, `51-code-simplification`, `52-security-and-hardening`, `53-performance-optimization` |
| `/ship` | `60-git-workflow-and-versioning`, `61-ci-cd-and-automation`, `62-deprecation-and-migration`, `63-documentation-and-adrs`, `64-shipping-and-launch` |

**El agente DEBE leer el `SKILL.md` correspondiente al inicio de cada fase**, no de memoria. El hook `PreToolUse` verifica que el archivo de skill fue leído antes de permitir acciones de esa fase.

---

## 4. Vocabulario prohibido (sin justificación)

Las siguientes expresiones disparan el hook anti-drift y requieren justificación explícita en el ledger antes de continuar:

```
"for now"            "por ahora"           "más adelante"        "later"
"MVP"                "rápido"              "quick fix"           "hack"
"temporal"           "temporary"           "we'll improve"       "lo mejoramos después"
"prototype"          "prototipo"           "good enough"         "es suficiente por ahora"
"skip the test"      "salto el test"       "skip tests"          "TODO: test later"
"// TODO" sin issue  "FIXME" sin issue     "XXX"                 "HACK:"
```

Si el agente o el humano usan una de estas, el agente DEBE:

1. Detenerse antes de la siguiente acción
2. Citar la palabra usada
3. Preguntar: _"Esto huele a deuda técnica deliberada. ¿Justificación para registrar en el ledger?"_
4. Esperar respuesta humana
5. Registrar la justificación en `.claude/ledger/<session>.jsonl` con tipo `drift_justified` o `drift_blocked`

**Excepción:** dentro de tags `<quote>...</quote>` el vocabulario no dispara el hook (para poder discutir el problema sin meta-loop infinito).

---

## 5. Sub-agentes especialistas

Invocables vía `Task` con el `subagent_type` correspondiente:

- **`code-reviewer`** — Senior Staff Engineer. Revisión de cinco ejes (corrección, claridad, complejidad, consistencia, cobertura). Estándar: _"¿Un staff engineer aprobaría esto?"_
- **`test-engineer`** — QA. Estrategia, cobertura, Prove-It pattern. Rechaza tests que solo verifican que el código compila.
- **`security-auditor`** — OWASP Top 10, threat modeling, secrets management.
- **`ux-designer`** — Generación y validación de design system. Aplica `35-design-system-generation`.
- **`devils-advocate`** — **Auto-invocado en cada transición de fase**. Su trabajo es objetar, no validar. Si está de acuerdo en todo, falló.

**Regla:** antes de cerrar `/review` o `/ship`, el agente DEBE invocar al menos `code-reviewer` + `devils-advocate`. Si la fase toca UI, también `ux-designer`. Si toca auth/input/red, también `security-auditor`.

---

## 6. Adaptación solo-developer

El usuario trabaja solo. Esto cambia tres cosas (no las elimina, las traduce):

### 6.1. Code review

No hay otro humano. La revisión se hace en dos pasos:

1. **Auto-revisión con delay obligatorio.** Después de implementar, esperar **mínimo 30 minutos** (o reanudar en sesión siguiente) antes de hacer `/review`. El hook `Stop` registra el timestamp; `/review` no inicia si han pasado <30 min sin un waiver explícito (`[waiver: <razón>]`).
2. **Devils-advocate adversarial.** Sub-agente obligatorio. Su salida se persiste en `.specs/<feature>/review.md`.

### 6.2. Pair programming

Se sustituye por _rubber-duck con escéptico_. Antes de empezar a codificar, el agente articula:

- Qué va a hacer
- Por qué esa aproximación y no otra (mínimo dos alternativas descartadas)
- Qué podría salir mal

Solo entonces empieza a escribir. Esto va al ledger como `pre_build_articulation`.

### 6.3. Standups / planning ceremonies

Reemplazadas por el ledger. Al inicio de cada sesión, el agente lee las últimas 3 entradas del ledger del proyecto y resume: _"Última sesión cerraste en fase X con artefacto Y. Pendiente: Z. ¿Continuamos o cambiamos foco?"_

---

## 7. Entorno macOS

Asumir:

- **Shell:** zsh por defecto (macOS 10.15+). Para hooks usar `#!/usr/bin/env bash` y código compatible con bash 3.2 (el de macOS sin Homebrew).
- **Utils:** BSD `sed`, BSD `date`, BSD `find`. Diferencias clave:
  - `sed -i ''` requiere argumento vacío después de `-i` en BSD (no en GNU)
  - `date -d` no existe en BSD; usar `date -j -f` o `date -v`
  - `find -printf` no existe en BSD; usar `-exec stat` o `-exec ls`
- **Paquetes:** Homebrew (`/opt/homebrew` en Apple Silicon, `/usr/local` en Intel). Detectar con `$(brew --prefix)`.
- **Notificaciones:** `osascript -e 'display notification "msg" with title "agent-rigor"'`
- **Apertura de archivos:** `open <path>` (no `xdg-open`).
- **Clipboard:** `pbcopy` / `pbpaste`.
- **Procesos:** `launchctl` para servicios; no `systemctl`.

**Nunca** asumir GNU coreutils a menos que el usuario haya instalado `brew install coreutils` y use prefijos `g` (`gsed`, `gdate`). Si un script lo requiere, fallar temprano con mensaje claro.

---

## 8. UI/UX: el flujo `design-system`

Cuando el cambio toque interfaz de usuario:

1. **Antes de cualquier componente**, generar o leer `design-system/MASTER.md`. Si no existe, ejecutar `/design` con descripción del producto.
2. **Para páginas/vistas específicas**, crear `design-system/pages/<page>.md` solo si hay desviaciones del MASTER. No duplicar.
3. **Patrón de recuperación contextual** (de `ui-ux-pro-max-skill`, adaptado):

   ```
   Estoy construyendo la página/componente [X].
   1. Leo design-system/MASTER.md (fuente de verdad global).
   2. Verifico si design-system/pages/[x].md existe.
   3. Si existe, sus reglas prevalecen sobre MASTER.
   4. Si no, uso MASTER exclusivamente.
   5. Aplico checklist pre-entrega de references/ui-ux-checklist.md.
   ```

4. **Checklist pre-entrega obligatoria** (de `references/ui-ux-checklist.md`):
   - [ ] No emojis como íconos (usar SVG: Heroicons/Lucide)
   - [ ] `cursor-pointer` en todo elemento clickable
   - [ ] Estados hover con transiciones suaves (150–300ms)
   - [ ] Contraste mínimo 4.5:1 (texto), 3:1 (UI)
   - [ ] Estados focus visibles para navegación por teclado
   - [ ] `prefers-reduced-motion` respetado
   - [ ] Responsive verificado en 375 / 768 / 1024 / 1440
   - [ ] Anti-patrones de la industria evitados (ver MASTER.md)

---

## 9. Session ledger

Archivo: `.claude/ledger/<YYYY-MM-DD>_<session-id>.jsonl`

Una línea JSON por evento. El agente debe escribir, vía bash o tool:

```jsonl
{"ts":"2026-05-13T10:32:11Z","type":"phase_enter","phase":"spec","feature":"auth-refresh"}
{"ts":"2026-05-13T10:45:02Z","type":"artifact_produced","path":".specs/auth-refresh/spec.md","sha":"abc123"}
{"ts":"2026-05-13T10:46:33Z","type":"drift_blocked","trigger":"for now","context":"...","resolution":"reformulated"}
{"ts":"2026-05-13T11:02:11Z","type":"phase_exit","phase":"spec","duration_min":30}
```

Tipos de evento estándar:

- `session_start`, `session_end`
- `phase_enter`, `phase_exit`
- `artifact_produced`
- `drift_detected`, `drift_blocked`, `drift_justified`
- `skill_read` (registrar cada `Read` de un `SKILL.md`)
- `subagent_invoked`, `subagent_returned`
- `skip_cycle_declared`
- `waiver_granted`

El benchmark lee estos ledgers para producir el scorecard.

---

## 10. Lo que NO hacer

- ❌ Comenzar a codificar sin spec, aunque "sea pequeño"
- ❌ Marcar como `done` sin tests pasando + evidencia
- ❌ Decir _"voy a hacer X simple por ahora"_ — eso es drift
- ❌ Saltar `devils-advocate` en `/review` o `/ship`
- ❌ Asumir GNU utils en macOS
- ❌ Modificar archivos en `skills/` durante una sesión normal (eso es trabajo meta, requiere `/spec` propio)
- ❌ Auto-confirmar transiciones de fase
- ❌ Resumir el ledger en vez de leerlo (los hooks lo verifican)

## 11. Qué SÍ hacer

- ✅ Producir artefactos persistentes en cada fase
- ✅ Articular el _porqué_ antes del _cómo_
- ✅ Pedir confirmación explícita en cada transición
- ✅ Invocar sub-agentes adversariales sin que el humano lo recuerde
- ✅ Registrar todo skip o waiver en el ledger con justificación
- ✅ Tratar al humano como senior — sin verbosidad innecesaria, sin disclaimers en cada respuesta
- ✅ Cuando una skill es ambigua, leer la skill ANTES de proponer interpretación

---

## 12. Sobre este archivo

Este `CLAUDE.md` se actualiza vía `/spec` propio (ver `.specs/_meta/` cuando aplique). Los hooks en `.claude/hooks/` se actualizan vía el mismo proceso. Cualquier cambio que afloje una compuerta requiere `[waiver: permanente]` en el ledger Y justificación en el PR.

**Última revisión:** ver `git log -1 CLAUDE.md`.
