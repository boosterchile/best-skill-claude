# macOS Setup

> agent-rigor is designed with macOS as first-class platform. Linux works but
> may need bash 5+ for some hook idioms; Windows is not supported.

## One-time machine setup

### Xcode Command Line Tools

```bash
xcode-select --install
```

Provides `git`, `clang`, headers. Required for most everything below.

### Homebrew

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

After install, ensure `brew` is on your PATH (the installer prints the lines for `.zprofile` or `.bash_profile`).

### Required tools

```bash
brew install jq git gh fswatch
brew install --cask claude  # if not already installed
```

### Optional but recommended

```bash
brew install ripgrep fd     # faster grep / find
brew install bat tree       # nicer ls / cat
brew install --cask gitleaks  # secret scanning
brew install hyperfine      # benchmark CLI tool
brew install --cask insomnia # API tester (alternative to Postman)
```

## Shell

agent-rigor's hooks are written for `bash 3.2+` (the version macOS ships with) so they run unmodified. You can use any login shell — `zsh` (default), `fish`, `bash` 5.x — they'll all execute the hooks correctly because hooks run under `/bin/bash` regardless.

If you want bash 5+ for your interactive shell:

```bash
brew install bash
sudo sh -c 'echo /opt/homebrew/bin/bash >> /etc/shells'  # M1/M2/M3/M4
sudo sh -c 'echo /usr/local/bin/bash >> /etc/shells'     # Intel
chsh -s /opt/homebrew/bin/bash   # adjust path for your arch
```

## BSD vs GNU utilities

macOS ships with BSD versions of `sed`, `awk`, `date`, `find`, `xargs`. The hooks use BSD-compatible idioms. If you've installed GNU versions via `brew install coreutils gnu-sed gawk`, the hooks still use the BSD versions (`/usr/bin/sed`, `/usr/bin/date`) by default.

You don't need GNU utilities. If you have them and prefer them in your shell, that's fine — the hooks run under their own subshell.

## Date arithmetic gotchas

The `to_epoch()` function in `benchmark/scripts/collect-metrics.sh` uses BSD `date` syntax:

```bash
date -u -j -f "%Y-%m-%dT%H:%M:%S" "$input" +%s
date -u -j -v-7d +%s
```

This is BSD-specific. The GNU equivalent is:

```bash
date -d "$input" +%s
date -d "7 days ago" +%s
```

If you ever port hooks elsewhere, update accordingly.

## Filesystem case sensitivity

By default, APFS on macOS is **case-insensitive** but **case-preserving**. This rarely matters for agent-rigor, but be aware:

- `git mv File.ts file.ts` works but git may need a two-step (`File.ts` → `File.ts.tmp` → `file.ts`)
- Paths in your spec.md should match the actual filesystem casing

If you work on a case-sensitive filesystem (rare on macOS unless you reformatted), nothing breaks.

## Claude Code configuration

`.claude/settings.json` is the only config file agent-rigor needs. The hooks are registered there:

```json
{
  "hooks": {
    "SessionStart": [{"command": "bash .claude/hooks/session-start.sh"}],
    "UserPromptSubmit": [{"command": "bash .claude/hooks/user-prompt-submit.sh"}],
    "PreToolUse": [{"command": "bash .claude/hooks/pre-tool-use.sh"}],
    "PostToolUse": [{"command": "bash .claude/hooks/post-tool-use.sh"}],
    "Stop": [{"command": "bash .claude/hooks/stop.sh"}]
  }
}
```

When Claude Code starts in your project, it reads this file and registers the hooks for the session.

If you have user-level `~/.claude/settings.json`, the project-level file takes precedence on conflicting keys. Hooks compose: both run.

## File watcher quirks

`fswatch` on macOS uses FSEvents and is efficient. Some IDE save patterns (atomic rename) trigger multiple events; if you build a test-on-save script, debounce:

```bash
fswatch -o --batch-marker --latency=0.3 src/ tests/ | \
  while read; do
    npm test
  done
```

## Spotlight indexing

Spotlight will index `.claude/ledger/*.jsonl` and `.specs/`. This is usually fine but if you have privacy concerns:

```bash
# In project root:
mdimport -X
touch .metadata_never_index
```

Or exclude the project root from Spotlight via System Settings → Siri & Spotlight → Spotlight Privacy.

## Performance: avoid the dock

If you ship UI work, run Lighthouse with the laptop on power, screen unlocked, and dock auto-hidden — battery throttling and dock animations skew first-render measurements:

```bash
# Disable dock auto-hide animation for measurements:
defaults write com.apple.dock autohide-time-modifier -float 0
killall Dock
# Restore default:
defaults delete com.apple.dock autohide-time-modifier
killall Dock
```

## Notarisation and macOS Gatekeeper

If you build native macOS binaries as part of your project:

- Sign with your Developer ID certificate
- Notarise via `xcrun notarytool submit ... --wait`
- Staple via `xcrun stapler staple <product>`

Out of scope for agent-rigor specifically, but the `64-shipping-and-launch` skill mentions it where relevant.

## Common macOS-specific issues

### "Operation not permitted" when running hooks

macOS may quarantine downloaded scripts. Fix:

```bash
xattr -d com.apple.quarantine .claude/hooks/*.sh 2>/dev/null
chmod +x .claude/hooks/*.sh
```

### `xcrun: error: invalid active developer path`

Means Xcode CLT was uninstalled or path lost. Reinstall:

```bash
sudo xcode-select --reset
xcode-select --install
```

### `gh` auth fails

```bash
gh auth status
gh auth refresh -h github.com -s repo,workflow,read:org
```

### `jq: command not found` despite `brew install jq`

PATH issue. Confirm:

```bash
which jq
echo $PATH
# Should contain /opt/homebrew/bin (M1+) or /usr/local/bin (Intel)
```

Add to `~/.zshrc` or `~/.bash_profile`:

```bash
eval "$(/opt/homebrew/bin/brew shellenv)"   # M1+
# or:
eval "$(/usr/local/bin/brew shellenv)"      # Intel
```

## VS Code / Cursor / Zed integration

agent-rigor doesn't require a specific editor. Useful settings if you use VS Code:

```json
{
  "files.watcherExclude": {
    "**/.claude/ledger/**": true,
    "**/benchmark/data/**": true,
    "**/benchmark/reports/**": true
  },
  "files.exclude": {
    "**/.claude/ledger/.current": true,
    "**/.claude/ledger/.last_source_write": true
  },
  "markdown.validate.enabled": true,
  "[markdown]": {
    "editor.wordWrap": "on",
    "editor.rulers": [80]
  }
}
```

## Apple Silicon vs Intel notes

All the tools above work identically on M1/M2/M3/M4 and Intel Macs. Two arch-specific paths:

- Homebrew on Apple Silicon: `/opt/homebrew/bin`
- Homebrew on Intel: `/usr/local/bin`

The hooks use absolute paths sparingly (`/bin/bash`, `/usr/bin/env bash`); your shell PATH handles the rest.

## When you're switching machines

To move agent-rigor to a new Mac:

```bash
# On old machine:
cd ~/your-project
tar czf /tmp/agent-rigor-state.tgz CLAUDE.md .claude/ skills/ benchmark/ references/ docs/

# On new machine:
cd ~/your-project
tar xzf /tmp/agent-rigor-state.tgz
chmod +x .claude/hooks/*.sh benchmark/scripts/*.sh
bash benchmark/scripts/collect-metrics.sh --self-check
```

The ledger does not transfer (it's session-specific) and shouldn't need to.

## When you're done with macOS

If you switch to Linux: the hooks need light porting (BSD `date`/`sed` → GNU). The skills themselves are platform-neutral. Open an issue if you want a Linux port; PRs welcome.
