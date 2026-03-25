# MAN PAGE Builder

Use this skill when the user asks to create, update, or standardize help/man pages for commands.

## Purpose
Create **optional help/man content** that is shown only when explicitly requested (e.g. `-h`, `--help`, `help`).

These man pages are **documentation artifacts**, not prompts for normal generation.

## Critical behavior (mandatory)
- Do **not** inject man page text into normal prompt templates.
- Do **not** prepend/append man page content to regular command execution prompts.
- Treat man pages as out-of-band help content.
- When a user triggers help (`-h`, `--help`, `help`), show the man page and stop; do not run normal generation logic.
- Prefer **script-based help routing** over AI extension routing to avoid token usage.

## Permanent storage + script standard
1. Store help docs in dedicated files:
   - `~/.pi/man/<command>.md` (preferred)
2. Use local scripts in `~/.local/bin`:
   - `piman` (generic man-page viewer)
   - `<command>-help` wrappers (e.g., `workflow-generate-help`)
3. Keep prompt templates minimal and operational.
4. Never require `/reload` for reading help; scripts must work independently.

## Authoring rules
- Keep examples copy-pasteable.
- Keep defaults explicit.
- Document required vs optional args.
- Keep help short by default; add “see also” links for depth.
- Never include secrets/tokens.
- Include sections:
  - NAME
  - SYNOPSIS
  - DESCRIPTION
  - OPTIONS
  - EXAMPLES
  - SEE ALSO (optional)

## Output contract
When building or updating help, always provide:
1. File path(s)
2. Final man/help content
3. Trigger rule used (must short-circuit generation)
4. Script wiring used (`piman` and/or `<command>-help`)

## Default trigger handling pattern
If input is `<command> -h`, `<command> --help`, or `<command> help`:
- execute local help script
- render man page only
- skip command generation flow
