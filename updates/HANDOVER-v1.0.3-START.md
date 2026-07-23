# HANDOVER — starting v1.0.3 (config & credentials interface)

Session starter. Read this, then `docs/CONTEXT.md`, `docs/DECISIONS.md`
(D-006, D-007) and `docs/DEVENV.md`.

## Goal for this increment
**v1.0.3 — the configuration & credentials interface (D-006).** Roger's stated
priority, ahead of bug fixing. One thing at a time, each accepted before coding.

## Where things stand
v1.0.2 is a documentation/baseline release on the fresh repo
(`github.com/rogerlayton/OneMuseum`, `main`, tag `v1.0.2`). No application code
has changed since v1.0.1. The v1.0.2 doc commit added D-004, D-005, and the
v1.0.3 planning recorded here.

## What triggered this increment (read before proposing anything)
On 2026-07-23 the app returned 500 on every request with no code change since
the previous day. Cause: `SECRET_KEY` and `MYSQLCONN_*` had been `export`ed
into a shell that was later closed. Nothing persisted them; recovering the
settings needed `docker inspect` on the running container.

Two distinct failures, both in scope:
1. **Config had no home** — shell-only, undocumented, unobtainable by a second
   developer.
2. **Missing config failed late and unreadably** — the app started fine, then
   every request (pages *and* static assets) raised the same `RuntimeError`
   about the missing secret key. ~40 identical tracebacks; nothing named the
   missing variable.

## Work items, in order
1. **F-011 — `.env` + `load_dotenv`.** Single config source, loaded however the
   app is launched. `.env` gitignored; **`.env.example` committed** with
   placeholders so the required set is discoverable from the repo.
2. **F-012 — fail-fast config validation.** Validate in `create_app()`; raise
   once naming **all** missing variables. *Blocked on Roger's ruling below.*
3. **F-013 — DB connection error handling.** Clear, actionable failure when
   MariaDB is unreachable / credentials wrong / database or procedures missing.
   (Connection-level; distinct from F-008's query-level work under D-005.)
4. **F-015 — simple diagnostic logging.** Minimal and readable: exception +
   route + SQL/procedure + params where relevant. Deliberately smaller than
   F-009; the need is "I can see where the error is".
5. **F-014 — least-privilege DB user.** App currently connects as MariaDB
   `root`. Give it SELECT + EXECUTE on the four procedures only. The dev
   container is disposable and can be recreated.

## Open question — needed before F-012
**Should missing required config prevent startup?** Recommendation: **yes** —
refuse to start and name every missing variable, converting a silent repeating
per-request failure into one unmissable message. Roger to rule.

## Also needed from Roger
- **Colleague's platform** (macOS / Windows / Linux) — `docs/DEVENV.md` is
  written for macOS and needs a note for hers.
- **Volume/persistence confirmation:**
  `docker inspect onemuseum-mariadb --format '{{json .Mounts}}'` — DEVENV
  documents a named volume, but the existing container's actual mount was never
  captured.
- **Credential rotation:** the dev root password was exposed in a chat
  transcript. Low stakes for a local throwaway container, but per D-006 it
  should be rotated — and must never have been shared with production.

## Not in this increment
- **D-007 user access control** (roles, permissions) — the next increment.
  **B-003** (hardcoded sign-in bypass) is removed *there*, not here, and must be
  gone plus history-scrubbed before public launch.
- **D-005 layered plan** (F-008 -> F-009 -> F-010) — follows D-007.
- **Images not displaying** — real, unresolved, and *not* a config problem;
  where images should be stored is an open design question (schema has
  `digitalobjects` / `digitalrepositories`). Needs its own investigation; do not
  fold it into this increment.

## Secrets discipline (applies immediately)
Never commit `.env` or `env.sh`. Docs use placeholders only. Real values go to
the second developer by direct secure channel, never via the repo or a shared
document. Dev credentials are throwaway and distinct from production.

## Method reminders
One thing at a time; reproduce before improving; docs and code land in the same
commit; decisions recorded before/with the code; explicit git sequences, never a
bare `git add`; `git push --tags` separately. Roger holds all decisions —
propose, do not expand scope. Fresh session per increment from a
`git archive HEAD` zip.
