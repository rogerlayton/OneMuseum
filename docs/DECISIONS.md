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
