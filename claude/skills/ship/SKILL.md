---
name: ship
description: Run the project's checks, commit, push the branch and open a GitHub pull request. Use when the owner says ship it, open a PR, make a PR, or when a change is finished.
argument-hint: "[optional PR title or notes]"
---

Ship the current work as a pull request. Extra instructions from the owner: $ARGUMENTS

Current state:
- Branch: !`git rev-parse --abbrev-ref HEAD`
- Default branch: !`git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | sed 's#origin/##'`
- Status: !`git status --short | head -50`

Steps:
1. If on the default branch, create `claude/<short-topic>` first (never commit to the default branch).
2. Look up the project's commands in the injected project context (or `ws show <project>`). Run, in order, lint → test → build
   (skip ones that are empty). Fix failures and re-run. If something cannot run here, note it for the PR body — never claim a pass you didn't see.
3. Commit remaining changes with conventional commit messages. Make sure no secrets or build artefacts are staged.
4. `git fetch origin` and rebase onto `origin/<default>` if behind; re-run tests if the rebase changed anything.
5. `git push -u origin HEAD` (never force-push, never push to the default branch).
6. If a PR already exists for this branch (`gh pr view --json url`), update it instead; otherwise create one:
   `gh pr create --base <default> --title "<conventional title>" --body-file <tmpfile>` with sections
   **Summary**, **Changes**, **Checks run** (command → result), **Risks / follow-ups**, and `Closes #N` if it fixes an issue.
   Respect `pr.draft` / `pr.reviewers` from the project config.
7. Reply with the PR URL and a 2–3 line summary. Then `gh pr checks --watch` is optional if the owner asks to wait for CI.
