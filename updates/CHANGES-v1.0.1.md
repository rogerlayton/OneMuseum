# CHANGES — v1.0.1

Cleanup & Flask-layout restructure. Behaviour-preserving; MariaDB unchanged.
Prior working version preserved at tag **v0.11**. Implements **D-001**, **D-002**, **D-003**.

## Structure
- Application moved into a named package `onemuseum/` (standard Flask layout).
- New `wsgi.py` entrypoint at project root (`gunicorn wsgi:app`).
- Former `app.py` retired: Jinja config + `highlight` filter moved into the
  `create_app()` factory; the `before_request` hook moved verbatim into
  `onemuseum/request_hooks.py`.

## Removed (dead weight)
- `site.db` (unused SQLite; Flask-tutorial residue).
- `db.py` (SQLite code contradicting the MariaDB data path; imported nowhere).
- `requirements2.txt`, `requirements3.txt` (stale/duplicate; two were UTF-16).

## Fixed
- **B-001:** `dbUpdate` called `dbClose()` where it meant `dbOpen()` — it
  failed on every call. Now opens a connection. *(Behaviour change — eyeball.)*
- **B2 (D-001):** `POCs` → `pocs` directory casing, so imports resolve on
  Linux (the blueprint is registered as `pocs`).
- **D-002:** SDF spec files now resolve relative to the package directory, not
  `os.getcwd()`, so SDF-driven pages work regardless of launch cwd.

## Dependencies (D-003 — Flask/Werkzeug 3 compatibility)
- **Flask 2.2.2 -> 3.1.3.** Flask 2.2.2 could not import under Werkzeug 3.x
  (`url_quote`), which is what failed when first applying the restructure.
- **Flask-Login 0.6.2 -> 0.6.3.** 0.6.2 hit the same wall (`url_decode`); 0.6.3
  is the first Werkzeug-3-compatible release.
- **Flask-WTF 1.0.1 -> 1.2.2**; **blinker 1.5 -> 1.9.0**; **click -> 8.1.7**
  (Flask 3.1 minimums). No app-code changes were needed (code scan clean).

## Requirements
- Single authoritative `requirements.txt` (runtime, Linux-installable).
- New `requirements-dev.txt` (pytest, lint, notebook; `pywin32` kept out of
  runtime — Windows-only).

## Hygiene
- All text files normalised to LF / UTF-8 (no BOM).

## Docs & process (new)
- `docs/DECISIONS.md` (D-001, D-002), `docs/BACKLOG.md`, `docs/CONFIG.md`,
  `docs/CONTEXT.md`.
- `tests/test_config_docs.py` — automated drift-check: fails if `config.py`
  env vars and `docs/CONFIG.md` disagree.
- `updates/` — this CHANGES, HANDOVER-v1.0.0, APPLY.md.

## Test baseline (this environment, no MariaDB)
- 8 passed / 1 failed. The failure is **B-002** (pre-existing, test-only:
  `test_menus` uses `menu_spec.items` without parens). DB tests
  (`test_dbutils_*`, `test_favourites`) collect but require MariaDB to run.

## Not done (parked — see docs/BACKLOG.md)
Postgres (F-001), containerization (F-002), UI reframe (F-003), asset diet
(F-004), requirements compat review (F-005), SQL identifier hardening (F-006),
snippet/POC housekeeping (F-007), dbutils error surfacing (F-008).

---

## Ready-to-copy commit (run AFTER tagging v0.11 — see updates/APPLY.md)

```
git add .
git commit -m "v1.0.1 — cleanup & Flask-layout restructure + Flask 3 deps (D-001..D-003)

Move app into onemuseum/ package; add wsgi.py entrypoint; retire app.py
(factory + request_hooks.py). Remove site.db, db.py, stale requirements.
Fix dbUpdate (B-001) and POCs->pocs casing. Anchor SDF spec paths to package
(D-002). Split runtime/dev requirements. Normalise to LF/UTF-8. Add docs/ and
updates/ scaffolding + config drift-check. Behaviour-preserving; MariaDB
unchanged. Prior version preserved at tag v0.11."
git tag v1.0.1
git push
git push --tags
```
