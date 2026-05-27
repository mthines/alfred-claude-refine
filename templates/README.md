# Templates

Each `.md` file in this directory is one Alfred option. The filename (without `.md`) is the **template key** — it's what `claude-refine` accepts as its first argument and what Alfred uses as the unique id.

## Format

```markdown
---
title: Display Name
description: One-line subtitle shown in Alfred
---
The actual instructions you want Claude to follow.

You can reference the input text in one of two ways:

1. Implicit (recommended): just write the instructions. The runner appends
   the user's text inside `<text-to-refine>...</text-to-refine>` tags and
   tells Claude to output only the rewritten result.

2. Explicit: include the literal token `{{INPUT}}` anywhere in the body and
   the runner will substitute the user's text there instead.
```

## Adding a template

1. Drop a new `.md` file in `~/.config/claude-refine/templates/` (or in this directory if you've put it on `$CLAUDE_REFINE_TEMPLATES_DIR`).
2. That's it. Alfred picks it up on the next invocation — no workflow re-import needed.

## Tips for writing prompts

- **Lead with a role.** "You are an editor." sets behavior more reliably than asking nicely.
- **Be explicit about what NOT to do.** Claude likes to "improve" things you didn't ask it to improve. Tell it to preserve voice, length, structure, etc.
- **Tell it not to add preamble.** Without this, you often get "Here is the rewritten text:" at the top. The runner already appends this instruction at the bottom of your prompt, but if you use `{{INPUT}}` explicitly you should add it yourself.
- **Constrain hallucination.** "Do not invent new facts, numbers, or names" prevents Claude from filling in plausible-sounding but wrong details when the original was vague.

## Overriding bundled templates

If you put a `concise.md` in `~/.config/claude-refine/templates/`, it shadows the bundled one — the user directory always wins when it exists.
