#!/bin/bash
# Remove claude-refine CLI symlinks, plus the workflow symlink and templates
# symlink if they were created via `./install.sh --dev`.
#
# Does NOT delete copied templates or workflows imported as a .alfredworkflow
# zip — those are user-owned and require explicit removal (see notes below).
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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

removed=0

# 1) CLI symlinks
for dir in /opt/homebrew/bin /usr/local/bin "$HOME/.local/bin" "$HOME/bin"; do
  for name in claude-refine claude-refine-templates; do
    target="$dir/$name"
    if [ -L "$target" ] || [ -f "$target" ]; then
      rm -f "$target"
      echo "→ Removed $target"
      removed=$((removed + 1))
    fi
  done
done

# 2) Templates dir symlink (only if it actually points at this repo)
TEMPLATES_DIR="$HOME/.config/claude-refine/templates"
if [ -L "$TEMPLATES_DIR" ]; then
  if [ "$(readlink "$TEMPLATES_DIR")" = "$REPO_ROOT/templates" ]; then
    rm "$TEMPLATES_DIR"
    echo "→ Removed templates symlink $TEMPLATES_DIR"
    removed=$((removed + 1))
  fi
fi

# 3) Workflow symlink in Alfred (only ones pointing at this repo)
if ALFRED_DIR=$(find_alfred_workflows_dir); then
  find "$ALFRED_DIR" -maxdepth 1 -type l 2>/dev/null | while read -r link; do
    if [ "$(readlink "$link")" = "$REPO_ROOT/workflow" ]; then
      rm "$link"
      echo "→ Removed workflow symlink $link"
    fi
  done
fi

if [ "$removed" -eq 0 ]; then
  echo "Nothing matched — no symlinks pointing at this repo were found."
fi

cat <<'EOF'

Done. Manual cleanup for non-symlink installs:
  • Alfred workflow imported via double-click:
      Alfred Preferences → Workflows → Claude Refine → ⋯ → Delete
  • Copied templates (non-dev install):
      rm -rf ~/.config/claude-refine
EOF
