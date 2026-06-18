# Claude Refine — Alfred Workflow

An Alfred workflow that runs selected or clipboard text through the **Claude CLI** with a markdown template, and auto-pastes the rewritten result back. Extensible — drop a new `.md` file into a directory and you have a new option.

Uses your existing Claude Code login (subscription) — no API key required.

## Why

I kept catching myself doing the same dance: copy a paragraph, switch to Claude, paste, type "rewrite this more concisely", wait, copy the result back. Five seconds of friction × dozens of times a day = real cost.

This collapses it to: select → `rw` → pick → done.

## Example

Input (something you typed in a hurry):

> Basically, what I'm trying to say is that we should probably go ahead and merge this PR pretty soon, because honestly it's been sitting around for a while now and we really need to move forward on this.

After `rw → Concise`:

> We should merge this PR soon — it's been sitting around too long and we need to move forward.

## How it works

```
                                                        ┌───────────────┐
[ Keyword "rw" ]──────────────────────────────────────▶ │               │
                                                        │ Script Filter │
[ Universal Action ]──▶[ Capture selection as $text ]──▶│  (templates)  │
                                                        │               │
                                                        └───────┬───────┘
                                                                ▼
                                                  ┌──────────────────────┐
                                                  │ Run Script           │
                                                  │  refine.sh <choice>  │
                                                  │   ↓ pipes text into  │
                                                  │  claude-refine       │
                                                  │   → claude -p ...    │
                                                  └─────────┬────────────┘
                                                            ▼
                                                ┌────────────────────────┐
                                                │ Copy to clipboard +    │
                                                │ auto-paste into app    │
                                                └────────────────────────┘
```

Two entry points feed into one templates picker. The picker is the only step that needs your attention.

## Install

**Prerequisites**: macOS, [Alfred 5](https://www.alfredapp.com/) with the Powerpack, and the [Claude CLI](https://docs.claude.com/en/docs/claude-code) signed in (`claude /login`).

```bash
git clone https://github.com/mthines/alfred-claude-refine.git
cd alfred-claude-refine
./install.sh
```

The installer:
1. Symlinks `claude-refine` and `claude-refine-templates` into a writable `bin/` directory on your `PATH` (prefers `/opt/homebrew/bin`, falls back to `/usr/local/bin`, then `~/.local/bin`).
2. Copies the bundled templates to `~/.config/claude-refine/templates/` — only if that directory doesn't already exist, so your customizations are never overwritten.
3. Builds `Claude Refine.alfredworkflow` (a zip of the `workflow/` directory) and offers to open it. Double-clicking that file imports the workflow into Alfred.

### Live-sync mode (for development)

If you want edits to flow into Alfred and back into the repo for committing:

```bash
./install.sh --dev
```

This:
- Symlinks the CLI binaries into `PATH` (same as default mode).
- Symlinks `<repo>/workflow/` into Alfred's workflows folder (auto-discovered from `~/Library/Application Support/Alfred/prefs.json`).
- Symlinks each bundled template into `~/.config/claude-refine/templates/` so edits propagate to the repo. Personal templates you add to the same directory remain real files and stay out of git.

Restart Alfred once after the first `--dev` install so it registers the workflow. After that, edits to templates, scripts, or `info.plist` propagate without restarting.

## Use

### From Alfred

- **Keyword**: type `rw` in Alfred. The list of templates appears. Pick one (or type to filter).
- **Universal Action**: select any text, invoke Alfred's Universal Actions, choose **Refine via Claude**, pick a template.
- **Custom instruction**: type any free-form instruction after `rw `. If your text doesn't match a template name, it's automatically treated as a one-off prompt. Example: `rw make this more focused on what it's trying to solve`. Prefix with `-` (`rw - <text>`) to force custom mode even when your text happens to match a template name.

Pre-bind the Universal Action to a hotkey in Alfred Preferences → Features → Universal Actions if you use it often.

#### Background vs foreground mode

Each template offers two ways to run, picked by the modifier key when you select it:

| Modifier | Mode | What happens |
| --- | --- | --- |
| `↩` | **Background** (default) | Rewritten text goes on the clipboard and a macOS notification fires when it's ready. Keep working in any app, then `⌘V` wherever you land. |
| `⌘ + ↩` | **Foreground** | Rewritten text is auto-pasted into the app you came from. Use when you'll stay put for the 3–5s rewrite. |

Hold `⌘` over an item in the Alfred picker to see the foreground-mode subtitle reminder.

### From the terminal

```bash
echo "this sentence is too long and has too many words" | claude-refine concise
pbpaste | claude-refine professional | pbcopy

# Custom one-off instruction (no template file needed)
echo "..." | claude-refine --instruction "make this more focused on what it's trying to solve"
```

## Templates

Each `.md` file in `~/.config/claude-refine/templates/` is one Alfred option.

```markdown
---
title: Display Name
description: Subtitle shown in Alfred
---
You are an editor. <Instructions for Claude here.>

Rules:
- Be specific about what to preserve (voice, length, structure, etc.).
- Tell Claude what NOT to do, not just what to do.
- Constrain hallucination: "do not invent new facts or numbers".
```

The runner appends the user's text inside a `<text-to-refine>...</text-to-refine>` block and tells Claude to output only the result. If you want to control placement yourself, include the literal `{{INPUT}}` token in your prompt and it will be substituted instead.

### Bundled templates

| Key | Title | What it does |
| --- | --- | --- |
| `concise` | Concise | Cut filler, combine sentences, preserve voice |
| `professional` | Professional | Polish to a clear, business-appropriate tone |
| `friendly` | Friendly | Warmer and more conversational, no corporate-speak |
| `grammar` | Fix Grammar | Grammar/spelling fixes only, voice preserved exactly |
| `expand` | Expand | Add helpful detail without inventing new facts |
| `structure` | Structure | Reorganize into clear sections, bullets, or flow |
| `clarify` | Clarify | Resolve ambiguity, replace vague pronouns |
| `slack` | Slack Message | Scannable, no email pleasantries, lead with the point |
| `email` | Email | Professional email body, polite close |
| `neutral` | Neutral Tone | Strip emotion and intensifiers, keep facts intact |

### Adding a template

Drop a new `.md` file into `~/.config/claude-refine/templates/`. That's it. Alfred picks it up on the next invocation. The filename (without `.md`) is the **template key**.

### Overriding a bundled template

Templates in `~/.config/claude-refine/templates/` shadow the bundled ones. If you want to tweak `concise.md`, just edit it there — the bundled version in the repo is irrelevant once your user copy exists.

### Where templates live

`~/.config/claude-refine/templates/` is the single source of truth — every template lives there as a regular file you can open, edit, or delete. `install.sh` seeds the directory from the repo's `templates/`:

| Mode | What `install.sh` does |
| --- | --- |
| `./install.sh` (default) | Copies each bundled template into `~/.config/claude-refine/templates/`. Files are independent: future repo updates do NOT propagate; your edits stay. Re-run `install.sh` on a file you've deleted to restore it. |
| `./install.sh --dev` | Symlinks each bundled template into `~/.config/claude-refine/templates/`. Editing a symlinked file edits the repo file directly — useful for committing template changes. Personal templates you add to the dir stay as real files and never end up in git. |

Existing files in the user dir are NEVER overwritten in either mode.

Set `$CLAUDE_REFINE_TEMPLATES_DIR=/some/dir` to bypass the user dir entirely and read only from that directory (useful for testing).

## Tips

- **Tweaks before pasting**: if you want to review before pasting, replace the final **Copy with Paste** node in the Alfred workflow with **Large Type** and a separate Copy node. Two-second change.
- **Per-app templates**: a `slack.md` you want only in Slack? Use the Universal Action route and the workflow's `focusedappvariable` field — or just always have `slack` available, it doesn't cost anything.
- **Speed**: `claude -p` takes 2–5s per call. That's the Claude CLI startup, not this workflow. If you want sub-second, swap the runner to the Anthropic API directly using an API key — see `bin/claude-refine` (one-line change to the `subprocess.run` call).

## Uninstall

```bash
./uninstall.sh
# Then in Alfred Preferences → Workflows → Claude Refine → ⋯ → Delete
# And:  rm -rf ~/.config/claude-refine
```

## Layout

```
alfred-claude-refine/
├── bin/
│   ├── claude-refine              # Main CLI — runs claude with a chosen template
│   └── claude-refine-templates    # Lists templates as Alfred Script Filter JSON
├── templates/                     # Bundled default templates (seed)
│   └── *.md
├── workflow/                      # Source for the Alfred workflow bundle
│   ├── info.plist
│   ├── refine.sh                  # Run Script the workflow invokes
│   └── list-templates.sh          # Script Filter the workflow invokes
├── install.sh
├── uninstall.sh
└── README.md
```

## License

MIT — see [LICENSE](./LICENSE).
