# VPS Workspace

This turns an Ubuntu VPS into a Claude Code development workspace that you drive from the Claude app on your phone or desktop:

- **Remote Control sessions.** Every project gets a long-running Claude Code session on the VPS. It shows up in the Claude app under **Code**, and each new chat gets its own git worktree.
- **Workspace Hub.** A separate session in `~/hub` that you talk to. It adds projects, stores project knowledge and changes configuration. Everything it stores is plain files in git, and it can back them up to a private GitHub repo.
- **Project memory.** Each project has a brief (`CONTEXT.md`) and running notes (`NOTES.md`). They're injected into every session automatically, and `/remember` adds to them.
- **PRs with checks.** `/ship` runs the project's lint, test and build commands, pushes a `claude/*` branch and opens a PR. Optional CI templates are in `templates/github/`.
- **Continuous development (optional).** Label a GitHub issue `claude` and the VPS implements it unattended and opens a PR.
- **Safe next to your websites.** Everything runs as a dedicated `claude-ws` user with no sudo and no web-group membership. That user is capped by systemd (memory 6G soft / 8G hard, low CPU and IO priority), and a watchdog restarts sessions that drop.

```
 Claude app (phone/desktop) ──Remote Control──►  VPS  user "claude-ws"
                                                 ├─ tmux "rc-hub"    claude remote-control  (~/hub)
                                                 ├─ tmux "rc-<proj>" claude remote-control  (~/projects/<proj>, worktrees)
                                                 ├─ ws-tick.timer    watchdog + hub backup   (every 5 min)
                                                 └─ ws-work.timer    issue worker → PRs      (every 10 min, opt-in per project)
```

## Install (once, about 10 minutes)

1. **Get this repo onto the VPS.** Push it to GitHub (it contains no secrets), then on the VPS:
   ```bash
   git clone https://github.com/<you>/vps-workspace.git ~/vps-workspace-src
   sudo bash ~/vps-workspace-src/install.sh
   ```
   If you'd rather not use GitHub, copy the folder over: `scp -r "VPS Workspace" you@vps:~/vps-workspace-src`.

2. **Log in as the workspace user:** `sudo -iu claude-ws`. The installer also copies your SSH key, so `ssh claude-ws@your-vps` works too.
   > Want a different name? Run the installer as `sudo WS_USER=yourname bash install.sh`. The installer refuses to reuse an existing account it didn't create, so your current `claude` user is left alone.

3. **Log Claude in with your subscription:** run `claude`, then type `/login`. Press **c** to copy the URL, open it on your phone or PC, paste the code back, then `/exit`.
   > A `claude setup-token` token is **not** enough here. Remote Control needs this full login. When the login nears expiry, Claude warns you; after it expires, run `/login` again.

4. **Log GitHub in.** Create a **fine-grained token** at github.com → Settings → Developer settings. Limit it to the repos you want Claude to work on, with these permissions: Contents (read/write), Pull requests (read/write), Issues (read/write), Workflows (read/write) and Metadata (read). Then:
   ```bash
   gh auth login        # GitHub.com → HTTPS → Paste an authentication token
   gh auth setup-git
   ```

5. **Finish setup:** `ws init` asks for the git author name and email, installs the services and starts the Hub. Then accept the one-time prompts:
   ```bash
   ws attach hub        # answer "Enable Remote Control? y" (and trust the folder if asked); detach with Ctrl-b then d
   ```

6. **Open the Claude app → Code.** You'll see **Workspace Hub**. Try: *"Add my repo github.com/me/shop. It's a Next.js webshop for…; tests run with npm test."*

7. **Recommended:** turn on branch protection for `main` on GitHub so changes only go in through PRs. Back up the Hub by telling it *"back up the hub to a private GitHub repo"*.

## Daily use (from your phone)

| You want to… | Do this |
|---|---|
| Work on a project | Open the project's session in the app and say what you want, e.g. *"add a contact form, then ship it"* |
| Open a PR | Type `/ship` (or just say "ship it") |
| Save project info | `/remember we deploy with GitHub Actions to /var/www/shop`, or tell the Hub |
| Add a project | Tell the Hub, or run `/add-project owner/repo` |
| Change config | Tell the Hub: *"put shop in plan mode"*, *"make PRs drafts"*, *"let Claude pick up issues on shop every 2h"* |
| Hand off work async | Create a GitHub issue with the label `claude` (needs `worker.auto_issues` turned on for that project) |
| Check health | Ask the Hub *"is everything ok?"*, or run `ws doctor` over SSH |

The full key reference is in `hub-template/README.md`, which becomes `~/hub/README.md`. The CLI help is under `ws help`.

## What's in this repo

```
install.sh                 root installer (packages, gh, user, resource caps, Claude Code, nvm/node, services)
bin/ws                     the workspace CLI (sessions, projects, config, worker, hub sync, SessionStart hook)
claude/CLAUDE.md           default global instructions (copied to ~/hub/global/CLAUDE.md on first init)
claude/settings.json       default permissions + hook (copied to ~/hub/global/settings.json)
claude/skills/             /ship  /remember  /add-project  /workspace
hub-template/              initial contents of ~/hub
systemd/                   user units: ws-up.service, ws-tick.timer, ws-work.timer
templates/project/         CONTEXT.md / NOTES.md templates
templates/github/          CI workflows + optional @claude GitHub Action
```

To update the tooling later: push changes to this repo, then run `ws self-update` on the VPS. Your Hub (config, notes, global rules) is never overwritten.

## Notes and limits

- If a Remote Control server loses the network for more than about 10 minutes, it exits. The `ws` loop restarts it after 15 seconds, and the watchdog restarts any session that has gone missing.
- Default permissions: file edits are auto-accepted. Common dev commands (git, gh pr/issue, npm, python, make…) are pre-allowed. `sudo`, force-pushes and reading secrets are denied. Pushing to `main`, merging PRs and `rm -rf` ask you first, and that prompt shows up in the app. Change any of this with the Hub (`global/settings.json`).
- The issue worker runs headless with an explicit allow-list (`--permission-mode dontAsk`). It cannot push or call `gh` itself; the `ws` script does the push and opens the PR.
- Pre-trusting folders writes `hasTrustDialogAccepted` into `~/.claude.json`. That's undocumented, so if it ever stops working you'll just get the trust prompt once in `ws attach <name>`.
- Usage counts against your Claude subscription limits. Long-running workers or many parallel chats use them up faster.
