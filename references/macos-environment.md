# macOS Environment

Reference for the assumptions agent-rigor makes about the runtime environment, the BSD vs GNU pitfalls, and the tooling baseline.

## Baseline assumed

| Requirement | Why | Install |
|---|---|---|
| macOS 14+ (Sonoma, Sequoia) | Bash 3.2 quirks tested on these versions | n/a |
| Bash 3.2 (system) | Hooks run via `#!/usr/bin/env bash`, must work without Homebrew bash | n/a (ships with macOS) |
| `jq` | Hook input is JSON; ledger entries are JSONL | `brew install jq` |
| `git` | Benchmark correlates ledger to commit history | `xcode-select --install` or `brew install git` |
| Claude Code CLI | Required to use this pack | `brew install --cask claude-code` |

Optional but recommended:

| Tool | Purpose | Install |
|---|---|---|
| `gh` | GitHub CLI for PR integration | `brew install gh` |
| `coreutils` | GNU utilities (gsed, gdate, gfind) for portable scripts | `brew install coreutils` |
| `ripgrep` | Faster grep | `brew install ripgrep` |
| `fzf` | Fuzzy finder for ledger exploration | `brew install fzf` |
| `bash` 5+ | Newer bash for ad-hoc scripts (hooks remain 3.2-compatible) | `brew install bash` |

## BSD vs GNU pitfalls

macOS ships BSD versions of common utilities. GNU versions behave differently. Hooks and scripts in agent-rigor avoid GNU-only flags.

### `sed -i`

```bash
# BSD (macOS):
sed -i '' 's/foo/bar/' file.txt    # empty arg required

# GNU (Linux):
sed -i 's/foo/bar/' file.txt        # no empty arg
```

Hooks use `sed -E 's/.../.../'` without `-i` (we pipe to a temp file when needed).

### `date`

```bash
# Get a relative time:

# BSD (macOS):
date -v-10M +%Y-%m-%dT%H:%M:%SZ

# GNU (Linux):
date -d "10 minutes ago" +%Y-%m-%dT%H:%M:%SZ
```

Hooks use BSD form with fallback:

```bash
TEN_MIN_AGO="$(date -u -v-10M +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"
```

Parse a known ISO date:

```bash
# BSD:
date -j -f "%Y-%m-%dT%H:%M:%SZ" "2026-05-13T10:00:00Z" +%s

# GNU:
date -d "2026-05-13T10:00:00Z" +%s
```

### `find`

```bash
# BSD does NOT support -printf
# Use -exec with stat or ls instead:
find . -name '*.md' -exec stat -f "%m %N" {} \;
```

`-mtime` works on both but BSD interprets days while GNU has flexible suffixes.

### `xargs`

GNU `xargs -d` (delimiter) doesn't exist on BSD. Use `tr` then pipe:

```bash
printf '%s' "$INPUT" | tr ',' '\n' | xargs -I{} ...
```

### `readlink`

```bash
# BSD: no -f flag for "canonical absolute path"
# Use this idiom instead:
PHYS_DIR="$(cd -- "$(dirname -- "$0")" && pwd)"
```

If you must use `readlink -f`, install coreutils and use `greadlink -f`.

### `realpath`

Not present in BSD. Use the same idiom as readlink, or rely on coreutils' `grealpath`.

### `wc -l`

BSD `wc -l` prefixes its output with whitespace. Always pipe through `tr -d ' '`:

```bash
COUNT="$(grep -c 'pattern' file | tr -d ' ')"
```

### `awk`

`awk` differs less between BSD and GNU. Most scripts portable. Avoid GNU `gawk` extensions (`gensub`, true-arrays, `length(array)`).

## Bash 3.2 limitations

macOS ships with bash 3.2 (Apple stopped updating due to GPL3). Hooks must work on 3.2.

What 3.2 lacks:

- Associative arrays (`declare -A`) — use indexed arrays + matching by index, or use jq for structured data
- `${var^^}` / `${var,,}` (upper/lowercase) — use `tr '[:lower:]' '[:upper:]'`
- `mapfile` / `readarray` — use `while IFS= read -r` loop
- `||=` style assignment — use explicit checks

Compatible idioms used in hooks:

```bash
# Lowercase a variable (3.2-safe):
LOWER="$(printf '%s' "$VAR" | tr '[:upper:]' '[:lower:]')"

# Read file into array (3.2-safe):
ARR=()
while IFS= read -r LINE; do
    ARR+=("$LINE")
done < file.txt
```

## Paths

- **Apple Silicon (M1/M2/M3/M4):** Homebrew lives at `/opt/homebrew`. Add `eval "$(/opt/homebrew/bin/brew shellenv)"` to your shell init.
- **Intel:** Homebrew lives at `/usr/local`.
- Detect: `BREW_PREFIX="$(brew --prefix 2>/dev/null || echo /usr/local)"`

User paths with spaces are common on macOS (`/Users/john smith/`). Hooks quote all paths.

## Notifications

Surface completion or block events via osascript:

```bash
osascript -e 'display notification "Spec ready for review" with title "agent-rigor" sound name "Glass"'
```

Quote characters in the message:

```bash
MSG="It's done"
osascript -e "display notification \"${MSG//\"/\\\"}\" with title \"agent-rigor\""
```

## Clipboard

```bash
# Copy:
echo "hello" | pbcopy

# Paste:
pbpaste
```

Useful for handing off Google Fonts URLs, color tokens, etc., to the user's editor or browser without leaving the terminal.

## Opening files / URLs

```bash
open .specs/feature/spec.md      # opens with default editor
open -a "Visual Studio Code" .   # opens VS Code in current dir
open https://github.com/...      # opens URL in default browser
```

## Filesystem case sensitivity

macOS default APFS is **case-insensitive** but **case-preserving**. `File.txt` and `file.txt` refer to the same file. If your project will be cloned on Linux (case-sensitive), avoid filename clashes that differ only in case.

Verify your volume:

```bash
diskutil info / | grep -i "case-sensitive"
```

## Permissions and the quarantine bit

Files downloaded from the internet receive a `com.apple.quarantine` extended attribute. Scripts will refuse to run until removed:

```bash
xattr -d com.apple.quarantine /path/to/script.sh
# or recursively:
xattr -dr com.apple.quarantine /path/to/dir
```

Apply this if hooks fail silently after a fresh clone.

## Ledger file sizes

Ledgers are JSONL. Over a long project they grow. Suggested rotation (manual, no cron):

```bash
# Monthly compress:
gzip .claude/ledger/2026-04*.jsonl
```

The benchmark scripts read both `.jsonl` and `.jsonl.gz` via `zcat` fallback.

## Verifying the install

```bash
bash benchmark/scripts/collect-metrics.sh --self-check
```

Expected output:

```
✓ bash 3.2+ available
✓ jq present (1.6+)
✓ git present
✓ macOS Darwin xx.x
✓ .claude/hooks/ all executable
✓ skills/ has 21 SKILL.md files
✓ ledger writable
✓ design-system/ writable
```

If any line shows ✗, follow the printed remediation.
