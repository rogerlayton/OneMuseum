# Backlog Archive — completed items

Full detail of **completed** features (**F-nnn**) and bugs (**B-nnn**).
Open items live in `BACKLOG.md`; its index lists every ID (open and done)
so numbers are never reused. When an item is completed, move its full entry
here and set its index line in `BACKLOG.md` to **DONE** with the version.

Cross-linked to decisions (**D-nnn**). Newest first.

---

## v1.0.5 (2026-07-26)

- **F-017 — dynamic version string on every page.** The page footer/nav
  version was the hardcoded literal `'v 0.11.1'` in `layout.html`, edited by
  hand each release and long out of date. Introduced a single source of truth:
  `__version__ = "1.0.5"` in `onemuseum/__init__.py`, exposed to all templates
  via an `inject_version` context processor, consumed in `layout.html` as
  `'v ' ~ app_version`. Nav now renders **V 1.0.5**. Route/render test added
  (`tests/test_templates.py`) with a reusable `client` fixture in
  `tests/conftest.py`. Status: **DONE** (v1.0.5).

---

## v1.0.4 → committed as v1.0.5 (2026-07-25)

- **F-013 — dbutils connection error surfacing.** (Concrete instance of F-008;
  Layer 1 of D-005.) `dbOpen()` previously caught connection errors, printed
  them, then fell through to return an unassigned `DBCONN`, raising
  `UnboundLocalError` one frame away from the real fault with the driver error
  discarded — and surfacing from callers' `finally: dbClose()`. Now raises
  `DBConnectionError` chaining the driver error as `__cause__`; `dbClose(None)`
  made safe; `DBCONN = None` bound before all 13 internal try blocks. 11 no-DB
  regression tests added (monkeypatch `mysql.connector.connect`). Status:
  **DONE** (v1.0.5). See `APPLY-v1.0.5.md`.

- **Admin tooling.** `Makefile` at project root (port 5001, `python -m
  flask/pytest` conventions); admin CLI `onemuseum/cli.py` (`create-user`,
  `reset-password`, `check-login`, `list-users`) registered directly on
  `app.cli`; `scripts/db.sh` (working DB connection: app user, TCP to
  127.0.0.1, password from `.env`); `docs/DB-ACCESS.md` (credential/connection
  traps); `SQL/DEV-wipe-users.sql`. Dev DB wiped and reset to three test
  accounts (roger/munirih/sholeen). Status: **DONE** (v1.0.4).

---

## v1.0.1 (2025)

- **F-005 — requirements runtime/dev split.** v1.0.0 split runtime/dev;
  v1.0.1 resolved the Flask/Werkzeug clash by bumping Flask 2.2.2→3.1.3 and
  Flask-Login 0.6.2→0.6.3, Flask-WTF→1.2.2 (D-003). `pywin32` stays dev-only
  (Windows). Status: **DONE** (v1.0.1).

---

## v1.0.0 (2025)

- **B-001 — `dbUpdate` called `dbClose()` instead of `dbOpen()`.** Failed on
  every call. Fixed in v1.0.0 (D-001). Status: **DONE**. (Roger to confirm any
  live code path through `dbUpdate` behaves as intended.)
