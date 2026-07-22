# Decisions Log

Numbered, dated design decisions. Status moves SPEC -> DONE in the landing
commit. This is the "why". Newest at the bottom.

Status legend: **SPEC** (agreed, not yet landed) · **DONE** (landed in code).

---

## D-001 — Cleanup & Flask-layout restructure, behaviour-preserving
**Date:** 2026-07-22 · **Status:** DONE (v1.0.1) · **Supersedes:** nothing

**Context.** The uploaded project (preserved as tag `v0.11`) had grown
organically. The project root *was itself* the Python package (relative
imports like `from .config`, `from ..dbutils`, and `app.py` doing
`from .__init__ import create_app`). This caused Linux-only breakage
(`POCs` vs `pocs` casing), carried dead SQLite-tutorial residue, had three
divergent requirements files (two UTF-16), CRLF line endings throughout, and
a broken `dbUpdate`.

**Decision.** Do a single behaviour-preserving increment that:
- moves the application into a named package `onemuseum/` (standard Flask
  layout), with `wsgi.py` at the project root as the entrypoint;
- removes dead weight (`site.db`, `db.py`, stale requirements);
- fixes the two correctness bugs (`dbUpdate`, `POCs`->`pocs`);
- normalises line endings/encoding to LF/UTF-8;
- establishes the four living docs and the updates/ release scaffolding.

**Explicitly NOT done (parked — see BACKLOG):** Postgres migration; any
SQLAlchemy/ORM adoption (rejected outright — `dbutils.py` is the chosen data
layer); rewriting `dbutils`; SDF-system rework; containerization; UI
reframe/retheme; SQL-identifier hardening; unused-asset diet.

**Behaviour change (the one to eyeball):** `dbUpdate` previously called
`dbClose()` where it meant `dbOpen()`, so it failed on every call. It now
opens a connection. This changes `dbUpdate` from "always fails" to "works".
See B-001.

**Verification.** Package byte-compiles; `create_app()` imports and builds
with all 9 blueprints, 51 URL rules, the `highlight` jinja filter, and the
moved `before_request` hook present. Full runtime render must be confirmed by
Roger in the real environment (MariaDB + env vars) before v1.0.0 is blessed.

**Convention established:** package = `onemuseum/`; entrypoint = `wsgi.py`
(`gunicorn wsgi:app`); the former `app.py` responsibilities are split into
the factory (`__init__.py`) and `request_hooks.py` (hook logic preserved
verbatim).

---

## D-002 — Anchor SDF spec paths to the package, not the working directory
**Date:** 2026-07-22 · **Status:** DONE (v1.0.1) · **Relates:** D-001

**Context.** `sdfutils.sdf_loader` resolved spec files as
`os.getcwd() + aFile`, e.g. `./static/specs/browsers/x.sdf`. In v0.11 the
package *was* the project root, so launching from there made the cwd-relative
path correct. The D-001 layout move puts specs at `onemuseum/static/specs/`
and runs `gunicorn wsgi:app` from the project root — under which the old
resolution would point at a non-existent `./static/specs/` and break every
SDF-driven page (browsers, details, menus, support).

**Decision (chosen over: constraining runtime cwd; or parking the layout
move).** Resolve spec files relative to the package directory
(`os.path.dirname(os.path.abspath(__file__))`) instead of `os.getcwd()`.
Caller paths are unchanged; the leading `/` in `aFile` is stripped and joined
under the package dir. This removes a hidden launch-cwd dependency rather than
relocating it — important ahead of containerization.

**Verification.** SDF browser/details specs load and parse; `sdf_menu('home')`
returns its dict with title "Home"; loading succeeds from an unrelated working
directory (`/tmp`), which the previous code could not do.

---

## D-003 — Bump Flask (and Flask-Login) for Werkzeug 3 compatibility
**Date:** 2026-07-22 · **Status:** DONE (v1.0.1) · **Relates:** D-001, F-005

**Context.** Applying v1.0.0, `flask --app wsgi run` failed at import with
`ImportError: cannot import name 'url_quote' from 'werkzeug.urls'`. The pinned
set was internally inconsistent: **Flask 2.2.2 cannot run under Werkzeug 3.x**
(Werkzeug 3.0 removed `url_quote`/`url_decode`/`url_encode`). A clean-venv
install then revealed **Flask-Login 0.6.2 has the same problem** (imports the
removed `url_decode`) — pinning it as-is only moves the error one import deeper.
The live v0.11 site therefore ran a different *real* pairing than the pins
claimed (an older Werkzeug alongside Flask 2.2.2).

**Decision (chosen: bump up, over pinning Werkzeug down).** Move to the current
stable, mutually-consistent set:
- `Flask 2.2.2 -> 3.1.3`
- `Flask-Login 0.6.2 -> 0.6.3` (first release with Werkzeug-3 compat)
- `Flask-WTF 1.0.1 -> 1.2.2` (safer CSRF integration under Flask 3)
- `itsdangerous 2.2.0`, `blinker 1.5 -> 1.9.0`, `click -> 8.1.7`
  (Flask 3.1 minimums)
Werkzeug/Jinja/MarkupSafe were already in the Flask-3 range.

**Why up, not down:** better footing for containerization and everything after;
avoids freezing the project on an EOL Flask 2.2 line.

**Verification.** Fresh venv install of the full `requirements.txt` resolves
cleanly; `create_app()` builds (9 blueprints, 51 routes, both before_request
hooks); `wsgi:app` imports. Code scan found **no** Flask-3-removed patterns in
the app (`flask.Markup`/`escape`, `_app_ctx_stack`, `before_first_request`,
direct `werkzeug.urls` use) — so no app-code changes were needed.

**Residual risk (for Roger's eyeball):** request-time behaviour of the
extensions under Flask 3 (form submit/CSRF via Flask-WTF, login/session via
Flask-Login, mail send) can only be confirmed against the running site + DB.
Supersedes the F-005 concern about the Flask/Werkzeug pin.

---

## D-004 — Fresh-repo git baseline; abandon prior GitHub history; tag v1.0.2
**Date:** 2026-07-22 · **Status:** DONE (v1.0.2) · **Relates:** D-001, APPLY(v1.0.1)

**Context.** The v1.0.1 handover's first work item was a git baseline that
never ran as written. `updates/APPLY.md` assumed the local tree was a git repo
whose history matched tag intent `v0.11`, to be overlaid onto the existing
GitHub `OneMuseum` repo. Reality on the Mac differed: the working tree
(`~/repos/onemuseum`) was an *extracted zip with no `.git` at all*, while the
real 213-commit history (incl. 13 tags) lived only on the GitHub `OneMuseum`
repo and was **not** connected to the local tree. Cloning to reconcile risked
the mixed-state trap; overlaying onto disconnected history risked worse.

**Decision (chosen over: clone-and-overlay; rename-and-reuse the old remote).**
Start the canonical repo **fresh**, deliberately abandoning the prior GitHub
history:
- Renamed the old GitHub repo `OneMuseum` -> **`OneMuseum-V0.11-old`** and
  retained it (archived, read-only) as the sole record of pre-restructure
  history. Nothing on it is carried forward.
- `git init` on the local v1.0.1 tree, branch **`main`**, single initial
  commit, tagged **`v1.0.2`**, pushed to a new empty
  **`github.com/rogerlayton/OneMuseum`**.

**Consequences (record honestly).**
- Tags **`v0.11`** and **`v1.0.1`** do **not** exist on the new remote. They
  survive only in the archived **`OneMuseum-V0.11-old`** repo. If pre-v1.0.2
  history is ever needed, it is recovered from there.
- The new repo's history begins at v1.0.2 as a single commit; per-change
  granularity before v1.0.2 is not present on the canonical remote by design
  (Roger's explicit call — "I do not need that old history").
- **v1.0.2 is a baseline/repo-reset release, not a feature release.** The tree
  is v1.0.1 plus documentation updates (this entry, D-005, backlog/context/
  handover). No application code changed.

**Auth note.** HTTPS push authenticated via the GitHub CLI (`gh auth login`,
browser flow), which wired git's credential helper into macOS Keychain.
GitHub account passwords are not accepted for git operations; a PAT or `gh`
is required.

**Verification.** `git push` reported `[new branch] main -> main`; `git push
--tags` reported `[new tag] v1.0.2`. Confirmed on github.com: files on `main`,
tag `v1.0.2` present.

---

## D-005 — Layered remediation plan: error handling -> logging -> test harness
**Date:** 2026-07-22 · **Status:** SPEC · **Relates:** F-008, F-009, F-010, B-004

**Context.** v1.0.2 is a clean baseline. A class of failures (anchor:
equations-lesson 500) is hard to diagnose because the data layer swallows
exceptions and there is no switchable logging. Before adding features or a
test harness, the diagnostic foundation must exist — you cannot golden-test a
page that returns a blank 500, and you cannot pin goldens against a moving
database without a fixture decision.

**Decision.** Adopt a three-layer sequence, done one at a time,
reproduce-before-improve, each surfaced for acceptance before coding:

1. **F-008 — dbutils error surfacing (root layer).** Stop the half-silent
   pattern (flash + return `False` into calling code). Surface/raise through a
   clear errors channel so failures are visible and diagnosable. Methodology
   §6 ("silent failures are traps") is the governing principle.
2. **F-009 — switchable logging.** Toggleable verbosity covering exception +
   route + SQL/proc + params. Independent of F-008 but pairs with it: together
   they make failures observable.
3. **F-010 — test harness, modelled on MathGL's structure.** Numbered
   dependency-ordered corpus, mirrored goldens, a runner with
   compare/accept/review verbs, deliberate human acceptance (the eyeball is
   when output becomes truth), seeded/pinned determinism, and a docs-in-step
   check (OneMuseum already has one: `tests/test_config_docs.py`), with CI
   running `compare` on push. Depends on layers 1 & 2.

**Ordering rationale.** Error handling is the root cause beneath the others;
logging makes failures observable; the harness needs both to assert against
real errors rather than swallowed ones.

**Adaptation from MathGL (important — not a copy-paste).** MathGL renders a
pure function (`input.mgl -> output.svg`, no external state), so its goldens
are deterministic file-renders. OneMuseum renders pages from **MariaDB via
stored procedures**, so page output depends on DB *data* that changes. F-010
therefore carries a **prerequisite decision**: a **pinned DB-fixture strategy**
(fixed seed dataset — e.g. the 7 June dump pinned — or golden the template
output against mocked query results). The unit of a OneMuseum corpus case is
likely a route request against a known DB state asserting on rendered HTML
(Flask test-client + golden HTML), not MathGL's file-render. This fixture
decision gets its own entry when F-010 is reached.

**Deferred within this plan — B-004 (the katex fork).** The anchor
equations-lesson 500 is `markdown-katex` needing a native `katex` binary
absent on the Mac (`NotImplementedError: katex binary not found`). The fix is
a genuine architectural fork — `npm install katex` (native binary) vs. move to
client-side KaTeX/MathJax (check how MathGL handled math) — and is **not**
decided here. Own entry when reached; do not one-line it.

**Not yet accepted.** This entry records the agreed *plan*; each layer's
implementation is accepted on its own before coding, per "one thing at a time".
