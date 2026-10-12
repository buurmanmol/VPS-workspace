# How I work on this VPS (global instructions — all projects)

You are running on the owner's VPS as an unprivileged, dedicated user (no sudo). The owner usually drives you from the
Claude app via Remote Control, often from a phone: keep replies short and scannable, and finish each task with a
one-paragraph summary plus the PR link.

## Where things live
- `~/projects/<name>` — git checkouts. Remote Control sessions for a project usually run in their own git worktree.
- `~/hub` — the Workspace Hub (a git repo, backed up): project briefs, notes, config, these global instructions.
  - `~/hub/projects/<name>/CONTEXT.md` — the project brief (goals, stack, users, decisions). Injected at session start.
  - `~/hub/projects/<name>/NOTES.md` — running log of learnings. The latest entries are injected at session start.
  - `~/hub/projects/<name>/project.json` — commands (setup/test/lint/build), PR and worker settings.
- `ws` — the workspace CLI (`ws help`). Use it for config changes instead of hand-editing JSON when possible.
- This machine also serves live websites. Never touch anything outside `~/` and never try to escalate privileges.

## Development workflow (every change)
1. Start from an up-to-date default branch: `git fetch origin`, then create a branch `claude/<short-topic>`
   (if you're in a fresh worktree, create/rename the branch there). Never commit directly to the default branch.
2. Read the project context first. If the setup command hasn't run in this checkout/worktree yet, run it.
3. Make focused changes. Add/adjust tests for behaviour you change.
4. Run the project's lint, test and build commands (from the injected context / `ws show <name>`). Fix what fails.
   Never claim checks passed without running them; if a check can't run here, say so in the PR.
5. Commit with conventional messages (`feat:`, `fix:`, `chore:` …).
6. Ship with `/ship`: push the branch and open a PR with `gh pr create` (summary, changes, checks run, risks).
   Don't merge PRs unless the owner explicitly asks.

## Memory
- When the owner tells you durable facts about a project (goals, conventions, credentials *locations* — never secrets
  themselves, architecture decisions, "always/never do X"), save them with `/remember` so every future session knows.
- Keep CONTEXT.md curated and concise (it's the brief); append dated one-liners to NOTES.md for smaller learnings.

## Safety
- Never print, read or commit secrets (`.env`, tokens, `~/.claude`, `~/.config/gh`, `~/.ssh`).
- No force-pushes. No pushing to the default branch. No deleting branches you didn't create.
- Keep resource use reasonable (no huge parallel builds); the websites on this box take priority.
