#!/bin/bash
# Alfred Script Filter: list templates as JSON.
# Invoked as: ./list-templates.sh "{query}"
set -euo pipefail

find_bin() {
  local name="$1"
  if command -v "$name" >/dev/null 2>&1; then
    command -v "$name"
    return 0
  fi
  for dir in /opt/homebrew/bin /usr/local/bin "$HOME/.local/bin" "$HOME/bin"; do
    if [ -x "$dir/$name" ]; then
      echo "$dir/$name"
      return 0
    fi
  done
  return 1
}

LT=$(find_bin claude-refine-templates) || {
  cat <<'JSON'
{"items":[{"title":"claude-refine-templates not found","subtitle":"Run install.sh from the alfred-claude-refine repo to install the CLI","valid":false}]}
JSON
  exit 0
}

exec "$LT" "${1:-}"
