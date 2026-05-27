#!/bin/bash
# Alfred Run Script: refine text via a Claude template.
#
# Invoked as: ./refine.sh <template-name>
# Reads input from either:
#   - $input_text  (set by the Argument-and-Variables node on the Universal Action path)
#   - the macOS clipboard via pbpaste (fallback used by the keyword path)
#
# Outputs the rewritten text on stdout, which becomes {query} for the next
# Alfred node (Copy to Clipboard with auto-paste).
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

TEMPLATE="${1:-}"
if [ -z "$TEMPLATE" ]; then
  echo "ERROR: No template selected." >&2
  exit 64
fi

CR=$(find_bin claude-refine) || {
  echo "ERROR: claude-refine not found on PATH. Run install.sh from the repo." >&2
  exit 127
}

TEXT="${input_text:-}"
if [ -z "$TEXT" ]; then
  TEXT=$(pbpaste 2>/dev/null || true)
fi
if [ -z "$TEXT" ]; then
  echo "ERROR: No input — neither a selection nor clipboard text was found." >&2
  exit 65
fi

# Two paths: __custom__ sentinel means use $custom_instruction (set by the
# Script Filter item's variables block); anything else is a regular template
# name. Command substitution strips trailing newlines, which is what we want
# for pasted output.
if [ "$TEMPLATE" = "__custom__" ]; then
  if [ -z "${custom_instruction:-}" ]; then
    echo "ERROR: custom instruction is empty." >&2
    exit 64
  fi
  OUTPUT=$(printf '%s' "$TEXT" | "$CR" --instruction "$custom_instruction")
else
  OUTPUT=$(printf '%s' "$TEXT" | "$CR" "$TEMPLATE")
fi
printf '%s' "$OUTPUT"
