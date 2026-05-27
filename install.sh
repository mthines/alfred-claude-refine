#!/bin/bash
# Install claude-refine.
#
# Default mode (end users):
#   - Symlinks the CLI into a writable PATH directory.
#   - Copies templates to ~/.config/claude-refine/templates (preserves customizations).
#   - Builds Claude Refine.alfredworkflow for Alfred to import via double-click.
#
# --dev mode (contributors):
#   - Same CLI symlinks.
#   - Symlinks ~/.config/claude-refine/templates → <repo>/templates (live sync).
#   - Symlinks the workflow directly into Alfred's workflows folder (live sync).
#   - Skips building the .alfredworkflow zip.
#
# After --dev, every edit you make in the repo is immediately live in Alfred
# and on the CLI. No re-import, no copy step.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

DEV_MODE=0
if [[ "${1:-}" == "--dev" ]]; then
  DEV_MODE=1
fi

pick_bin_dir() {
  for dir in /opt/homebrew/bin /usr/local/bin "$HOME/.local/bin"; do
    if [ -d "$dir" ] && [ -w "$dir" ]; then
      echo "$dir"
      return
    fi
  done
  mkdir -p "$HOME/.local/bin"
  echo "$HOME/.local/bin"
}

find_alfred_workflows_dir() {
  local current
  current=$(python3 -c "
import json, sys
try:
    p = json.load(open('$HOME/Library/Application Support/Alfred/prefs.json'))
    print(p.get('current', ''))
except Exception:
    sys.exit(1)
" 2>/dev/null || true)
  if [ -n "$current" ] && [ -d "$current/workflows" ]; then
    echo "$current/workflows"
    return 0
  fi
  return 1
}

if [ "$DEV_MODE" -eq 1 ]; then
  echo "Claude Refine — installer (--dev: live-sync mode)"
else
  echo "Claude Refine — installer"
fi
echo ""

# 1) Warn if the Claude CLI is missing
if ! command -v claude >/dev/null 2>&1; then
  echo "⚠️  'claude' CLI not found on PATH."
  echo "    Install Claude Code first: https://docs.claude.com/en/docs/claude-code"
  echo ""
fi

# 2) Install the CLI symlinks
BIN_DIR=$(pick_bin_dir)
echo "→ Linking CLI into $BIN_DIR"
chmod +x "$REPO_ROOT/bin/claude-refine" "$REPO_ROOT/bin/claude-refine-templates"
ln -sf "$REPO_ROOT/bin/claude-refine" "$BIN_DIR/claude-refine"
ln -sf "$REPO_ROOT/bin/claude-refine-templates" "$BIN_DIR/claude-refine-templates"

# 3) User templates dir — for personal templates that layer on top of the bundled
# set. The CLI auto-discovers bundled templates from the repo via the script's own
# __file__ resolution, so we never need to copy or symlink the defaults.
TEMPLATES_DIR="$HOME/.config/claude-refine/templates"
mkdir -p "$TEMPLATES_DIR"
if [ -z "$(ls -A "$TEMPLATES_DIR" 2>/dev/null)" ]; then
  echo "→ Created empty $TEMPLATES_DIR (drop .md files here to add personal templates)"
else
  echo "→ Personal templates dir at $TEMPLATES_DIR ($(ls -1 "$TEMPLATES_DIR" 2>/dev/null | wc -l | tr -d ' ') file(s))"
fi

# 4) Alfred workflow: symlink in dev mode, build a .alfredworkflow zip otherwise
if [ "$DEV_MODE" -eq 1 ]; then
  if ALFRED_DIR=$(find_alfred_workflows_dir); then
    existing=$(find "$ALFRED_DIR" -maxdepth 1 -type l 2>/dev/null | while read -r link; do
      if [ "$(readlink "$link")" = "$REPO_ROOT/workflow" ]; then
        echo "$link"
        break
      fi
    done)
    if [ -n "$existing" ]; then
      echo "→ Workflow already symlinked at $(basename "$existing")"
    else
      uuid=$(uuidgen)
      target="$ALFRED_DIR/user.workflow.$uuid"
      ln -s "$REPO_ROOT/workflow" "$target"
      echo "→ Symlinked workflow into Alfred:"
      echo "  $target"
      echo "  → $REPO_ROOT/workflow"
    fi
    echo ""
    echo "⚠️  Restart Alfred (or quit + reopen Preferences) to register the workflow."
  else
    echo "→ Could not locate Alfred's workflows folder. Skipping workflow symlink."
    echo "  (Alfred sync folder is configured in Alfred → Preferences → Advanced → Sync)"
  fi
else
  WORKFLOW_ZIP="$REPO_ROOT/Claude Refine.alfredworkflow"
  echo "→ Building $WORKFLOW_ZIP"
  rm -f "$WORKFLOW_ZIP"
  (cd "$REPO_ROOT/workflow" && zip -qr "$WORKFLOW_ZIP" .)

  if [ -t 0 ]; then
    printf "\nImport workflow into Alfred now? [Y/n] "
    read -r yn || yn="Y"
    yn=${yn:-Y}
    if [[ "$yn" =~ ^[Yy]$ ]]; then
      open "$WORKFLOW_ZIP"
    else
      echo "  Open it later with:  open \"$WORKFLOW_ZIP\""
    fi
  fi
fi

# 5) PATH warning if the bin dir isn't on PATH
case ":$PATH:" in
  *":$BIN_DIR:"*) ;;
  *)
    echo ""
    echo "⚠️  $BIN_DIR is not on your PATH."
    echo "    Add it to your shell profile:"
    echo "      echo 'export PATH=\"$BIN_DIR:\$PATH\"' >> ~/.zshrc"
    echo "    Then restart your shell."
    ;;
esac

echo ""
echo "✓ Done. Try it:"
echo "    echo 'this sentence is too long' | claude-refine concise"
echo ""
if [ "$DEV_MODE" -eq 1 ]; then
  echo "  Dev tip: every edit in this repo is now live. No re-install needed."
else
  echo "  In Alfred:"
  echo "    1. Copy any text"
  echo "    2. Type 'rw' in Alfred → pick a template"
  echo "    3. The rewritten text is auto-pasted"
fi
