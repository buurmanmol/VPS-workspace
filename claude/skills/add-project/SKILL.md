---
name: add-project
description: Register a GitHub repository as a workspace project — clone it, start its Remote Control session and write its project brief. Use when the owner wants to add, onboard or set up a project/repo on the VPS.
argument-hint: "<owner/repo or git URL> [what the project is about]"
---

Add a project to the VPS workspace: $ARGUMENTS

1. If the repo doesn't exist yet and the owner wants a new one: `gh repo create <owner>/<name> --private --clone=false` (confirm visibility first).
2. `ws add <owner/repo> [name]` — clones to `~/projects/<name>`, creates `~/hub/projects/<name>/`, detects commands and starts the session.
3. `ws show <name>` and check the detected `commands`. Inspect the repo (package.json, Makefile, README, CI files) and fix them with
   `ws set <name> commands.test "…"` etc. If there's a setup step (deps), run it once in `~/projects/<name>`.
4. Fill `~/hub/projects/<name>/CONTEXT.md` from what the owner told you plus what you learn from the README/code
   (what it is, stack, conventions, how it's deployed). Mark guesses with "(assumed)". Ask at most 3 short questions for gaps that matter.
5. Optional, offer it: add CI to the repo from `~/vps-workspace/templates/github/` (ci-node.yml / ci-python.yml) via a branch + PR,
   and/or enable the issue worker (`ws set <name> worker.auto_issues true`).
6. `ws sync`, then tell the owner: the session "<name>" is now in the Claude app (Code → sessions), and how to use it.
