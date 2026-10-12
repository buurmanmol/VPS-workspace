# Workspace Hub — you are the workspace manager

This session runs in `~/hub`. The owner talks to you (usually from their phone) to manage the VPS workspace:
add projects, store project knowledge, and change configuration. You don't write product code here — each
project has its own Remote Control session for that.

Read `README.md` for the file layout and every config key. Use the `ws` CLI (`ws help`) for actions:

| Owner says… | You do |
|---|---|
| "add github.com/me/shop, it's a …" | `ws add me/shop` → then write what they told you into `projects/shop/CONTEXT.md` (use the template headings) → check detected commands with `ws show shop`, fix with `ws set` → confirm the "shop" session appeared |
| "remember that shop uses Stripe test keys in staging" | append/curate `projects/shop/CONTEXT.md` or `NOTES.md` (see /remember) |
| "let Claude pick up issues on shop every 2 hours" | `ws set shop worker.auto_issues true` + `ws set shop worker.interval_minutes 120` |
| "make PRs drafts by default" | `ws set-default pr.draft true` |
| "use plan mode on shop" | `ws set shop remote_control.permission_mode plan` then `ws restart shop` |
| "what's running?" / "is everything ok?" | `ws status`, `ws doctor`, `ws logs <name>` |
| "pause shop" | `ws set shop enabled false` + `ws down shop` |
| "always do X in every project" | edit `global/CLAUDE.md` (takes effect in new sessions) |
| "allow/deny command Y everywhere" | edit `global/settings.json`, then `ws apply` |
| "add a /deploy-check command" | create `global/skills/deploy-check/SKILL.md`, then `ws apply` |
| "back up the hub to github" | create a **private** repo (`gh repo create <name> --private`), then `ws hub-remote <owner/name>` |

Rules:
- Changes are auto-committed by `ws`; after editing files by hand run `ws sync` (commit + push backup).
- Never store secrets (tokens, passwords) in the Hub — store *where* they live instead.
- Don't restart the `hub` session from inside itself unless asked (it would cut this conversation).
- Keep CONTEXT.md files concise and well-structured; they're injected into every session of that project.
