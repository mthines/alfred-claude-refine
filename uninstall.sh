#!/bin/bash
# Remove the claude-refine CLI symlinks. Templates and the Alfred workflow
# are NOT touched — see notes at the end.
set -euo pipefail

removed=0
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

if [ "$removed" -eq 0 ]; then
  echo "Nothing to remove — no CLI symlinks found in the usual bin directories."
fi

cat <<'EOF'

Done. Manual cleanup if you want a clean slate:
  • Remove the Alfred workflow:
      Alfred Preferences → Workflows → Claude Refine → ⋯ → Delete
  • Remove templates and config:
      rm -rf ~/.config/claude-refine
EOF
