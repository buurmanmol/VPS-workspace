---
name: remember
description: Save durable project knowledge (goals, conventions, decisions, gotchas) to the Workspace Hub so every future session knows it. Use when the owner says remember, note that, from now on, always/never, or shares project information.
argument-hint: "<what to remember>"
---

Store this in the Workspace Hub: $ARGUMENTS

1. Work out the project name: the injected "Project context: <name>" heading, or `basename $(dirname $(git rev-parse --path-format=absolute --git-common-dir))`.
   In the Hub session, ask which project if it isn't obvious (or use `global/CLAUDE.md` for things that apply everywhere).
2. Decide where it belongs:
   - Lasting facts about the product, stack, conventions, environments, decisions, don'ts → edit the matching section of
     `~/hub/projects/<name>/CONTEXT.md` (keep it concise; update/replace outdated lines rather than appending contradictions;
     decisions get a `YYYY-MM-DD — decision — why` line).
   - Small learnings, gotchas, status → append `- YYYY-MM-DD — <one line>` to `~/hub/projects/<name>/NOTES.md`.
   - Longer specs/docs → `~/hub/projects/<name>/<topic>.md` (it will be listed in every session's context).
   - Rules for all projects → `~/hub/global/CLAUDE.md`.
3. Never store secrets — store where they live (e.g. "Stripe key: in /var/www/shop/.env on the VPS").
4. Run `ws sync` to commit (and back up), then confirm in one line what you saved and where.
