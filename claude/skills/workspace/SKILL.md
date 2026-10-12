---
name: workspace
description: Inspect or change VPS workspace configuration — sessions, permission modes, models, the issue worker, PR defaults, global rules, settings and skills. Use when the owner asks to configure, enable, disable, pause, restart, or check the status of the workspace or a project.
argument-hint: "<what to change or check>"
---

Request: $ARGUMENTS

Current state: !`ws status --brief 2>&1`

- Read `~/hub/README.md` for every config key and the file layout; `ws help` for commands.
- Project-level change → `ws set <name> <key.path> <value>` (values are parsed as JSON when possible: `true`, `120`, `["a","b"]`).
- Workspace-wide default → `ws set-default <key.path> <value>`.
- Remote Control settings (`remote_control.*`, `enabled`) need `ws restart <name>`; warn the owner this ends that project's open chats.
  Never restart `hub` from the Hub session unless explicitly asked.
- Rules for every session → edit `~/hub/global/CLAUDE.md`. Permissions/hooks → edit `~/hub/global/settings.json` then `ws apply`.
  New slash command → `~/hub/global/skills/<name>/SKILL.md` then `ws apply`.
- Diagnose with `ws doctor`, `ws logs <name>`.
- Finish with `ws sync` and a one-line confirmation of what changed.
