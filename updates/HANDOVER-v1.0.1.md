# HANDOVER — v1.0.1

## What shipped
Cleanup & Flask-layout restructure (D-001, D-002, D-003), behaviour-preserving,
MariaDB unchanged. App now lives in the `onemuseum/` package with a `wsgi.py`
entrypoint; `app.py` retired into the factory + `request_hooks.py`. Dead
weight removed (`site.db`, `db.py`, stale requirements). Fixed `dbUpdate`
(B-001) and `POCs`->`pocs` casing. SDF spec paths anchored to the package
(D-002). Runtime/dev requirements split. LF/UTF-8 normalised. Four living
docs + config drift-check test + updates/ scaffolding established. Prior
working version preserved at tag **v0.11**.

## Next target
Roger's call. Natural candidates, each its own increment: containerization
against MariaDB (F-002), then Postgres (F-001). UI reframe (F-003) is
independent and can be sequenced anytime; workbook scans + screen dumps feed
it.

## Open — awaiting Roger
- **Verify v1.0.1 in the real environment** (MariaDB + env vars): app launches
  via `gunicorn wsgi:app`, and key pages render identically to v0.11 (now on Flask 3.1.3) —
  a browser list, a details page, a categories page, a menu. This is the
  eyeball that blesses v1.0.1. I could not run the full app here (no DB, and
  AI-side renders are not the real environment).
- Confirm any live code path through `dbUpdate` now behaves as intended (B-001
  changed it from always-failing to working).
- Provide MariaDB data model + the four stored-proc bodies **when** F-001
  (Postgres) starts — not before (avoids a stale copy).
- Send workbook scans + screen dumps for backlog intake (F-003 and general).

## Also open (parked, not blocking)
F-004 asset diet, F-005 requirements compat review, F-006 SQL identifier
hardening, F-007 snippet/POC housekeeping, F-008 dbutils error surfacing,
B-002 test_menus defect. See docs/BACKLOG.md.

## Process notes
- Tag **v0.11 on the current un-restructured commit BEFORE applying v1.0.0** —
  otherwise the preserved "old version" would contain the new structure (the
  stale-snapshot trap). Full ordering in updates/APPLY.md.
- Git sequence is written complete and explicit (`git add .` first, never a
  bare `git add`), per methodology §4.
- Test baseline here: 8 passed / 1 failed (B-002, pre-existing, test-only). DB
  tests require MariaDB to run.
