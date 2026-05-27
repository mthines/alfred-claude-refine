#!/bin/bash
# Install claude-refine CLI + seed templates + build & open the Alfred workflow.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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

echo "Claude Refine — installer"
echo ""

# 1) Sanity: claude CLI present?
if ! command -v claude >/dev/null 2>&1; then
  echo "⚠️  'claude' CLI not found on PATH."
  echo "    Install Claude Code first: https://docs.claude.com/en/docs/claude-code"
  echo "    Then re-run this installer."
  echo ""
fi

# 2) Pick a writable bin dir and install the CLI as symlinks
BIN_DIR=$(pick_bin_dir)
echo "→ Installing CLI to $BIN_DIR"
chmod +x "$REPO_ROOT/bin/claude-refine" "$REPO_ROOT/bin/claude-refine-templates"
ln -sf "$REPO_ROOT/bin/claude-refine" "$BIN_DIR/claude-refine"
ln -sf "$REPO_ROOT/bin/claude-refine-templates" "$BIN_DIR/claude-refine-templates"

# 3) Seed user templates dir if absent
TEMPLATES_DIR="$HOME/.config/claude-refine/templates"
if [ ! -d "$TEMPLATES_DIR" ]; then
  echo "→ Seeding templates → $TEMPLATES_DIR"
  mkdir -p "$TEMPLATES_DIR"
  cp "$REPO_ROOT"/templates/*.md "$TEMPLATES_DIR/"
else
  echo "→ Templates dir already exists at $TEMPLATES_DIR (preserving your customizations)"
  echo "  To add new bundled templates, copy them manually:"
  echo "    cp $REPO_ROOT/templates/<name>.md $TEMPLATES_DIR/"
fi

# 4) Build the .alfredworkflow bundle (a zip of workflow/)
WORKFLOW_ZIP="$REPO_ROOT/Claude Refine.alfredworkflow"
echo "→ Building $WORKFLOW_ZIP"
rm -f "$WORKFLOW_ZIP"
(cd "$REPO_ROOT/workflow" && zip -qr "$WORKFLOW_ZIP" .)

# 5) Offer to open in Alfred
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

# 6) PATH warning if the bin dir isn't on PATH
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
echo "  In Alfred:"
echo "    1. Copy any text"
echo "    2. Type 'rw' in Alfred → pick a template"
echo "    3. The rewritten text is auto-pasted"
