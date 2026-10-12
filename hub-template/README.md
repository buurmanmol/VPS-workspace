# Workspace Hub

The brain of the VPS workspace. Everything here is plain files in git, so it is versioned and (with
`ws hub-remote`) backed up to a private GitHub repo.

```
workspace.json            workspace-wide defaults (Hub session, Remote Control, worker, PR)
global/CLAUDE.md          instructions for every Claude session on this VPS  (→ ~/.claude/CLAUDE.md)
global/settings.json      Claude Code settings: permissions, hooks            (→ ~/.claude/settings.json via `ws apply`)
global/skills/<n>/SKILL.md your own slash-commands/skills                     (→ ~/.claude/skills via `ws apply`)
projects/<name>/
  project.json            repo, branch, commands, remote_control, worker, pr settings
  CONTEXT.md              project brief — injected into every session of this project
  NOTES.md                running notes — latest entries injected into every session
  *.md                    any extra docs (specs, decisions); listed in the session context
archive/                  removed projects
```

Config keys in `project.json` (missing keys fall back to `workspace.json` → `defaults`):

| key | meaning |
|---|---|
| `enabled` | run a Remote Control session for this project |
| `remote_control.spawn` | `worktree` (each new chat gets its own git worktree) · `same-dir` · `session` |
| `remote_control.capacity` | max concurrent chats |
| `remote_control.permission_mode` | `acceptEdits` · `default` · `plan` · `auto` |
| `remote_control.model` / `title` | optional model / display name |
| `commands.setup/test/lint/build` | what Claude runs before opening a PR |
| `worker.auto_issues` | auto-implement issues labelled `worker.label` and open PRs |
| `worker.interval_minutes`, `max_turns`, `timeout_minutes`, `model`, `allow` | worker tuning; `allow` = extra permission rules |
| `pr.draft`, `pr.reviewers` | PR defaults |
