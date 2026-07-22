# Project Context (cold-start)

Read this first to resume the project from scratch (human or AI).

## What it is
OneMuseum — a Flask web application (live at onemuseum.net). Museum/curriculum
data browser: entities, categories, details pages, user accounts, favourites.

## Stack
- **Flask** application-factory + blueprints. No ORM.
- **Data layer:** hand-rolled raw SQL through `onemuseum/dbutils.py` against
  **MariaDB/MySQL** (`mysql.connector`). Opens/closes a connection per call.
  This is a deliberate, kept design — **not** to be replaced with SQLAlchemy.
- **Auth:** Flask-Login + Flask-Bcrypt. `User` in `onemuseum/models.py` is
  hand-hydrated from SQL rows (not an ORM model).
- **SDF system:** `onemuseum/sdfutils.py` + `static/specs/` — a small
  home-grown declarative spec language defining each entity's browser (SQL
  fragments, columns, ordering, search/where, pagination).
- **Runtime stored procedures (MariaDB):** `GenDetails`, `ChenhallDetails`,
  `GenCategories`, `UserEntityFavourite` (called via `callproc`).
- **UI:** Now UI Kit Pro v1.3.1 (Bootstrap 4). Jinja templates in
  `onemuseum/templates/`, assets in `onemuseum/static/`.

## Layout (post v1.0.1)
```
onemuseum/            application package
  __init__.py         create_app() factory + extensions
  request_hooks.py    before_request hook (session timeout + activity log)
  config.py           Config from environment (see docs/CONFIG.md)
  dbutils.py          THE data layer (raw SQL). Do not casually change.
  sdfutils.py         SDF spec loader/parser
  cache.py models.py
  <blueprint>/routes.py   admin, categories, entities, errors, images,
                          main, support, users, pocs
  templates/ static/ snippets/
wsgi.py               entrypoint: gunicorn wsgi:app
tests/                pytest (imports as onemuseum.*)
docs/                 DECISIONS, BACKLOG, CONFIG, CONTEXT (this file)
updates/              per-release CHANGES / HANDOVER / APPLY
SQL/                  schema, procedures, data (bulk/restore)
_DevNotes/            historical freeform notes
```

## How to run
See docs/CONFIG.md. Needs the `MYSQLCONN_*` env vars pointing at MariaDB, plus
`SECRET_KEY` and `MAIL_*`. `gunicorn wsgi:app` (prod) or `flask --app wsgi run`
(dev).

## Conventions
- Small increments, one thing at a time; fresh session per increment from a
  `git archive HEAD` zip. Docs and code move together in the same commit.
- Versioning MAJOR.RELEASE.CHANGE; tag every release; `git push --tags`.
- Decisions recorded in docs/DECISIONS.md BEFORE/WITH the code (D-nnn).
- The working prior version is the spec; reproduce first, improve deliberately.

## Current state
At **v1.0.2**: fresh-repo git baseline (D-004). The canonical repo is now
**github.com/rogerlayton/OneMuseum** (branch `main`, tag `v1.0.2`), pushed
2026-07-22. Prior GitHub history was deliberately abandoned and archived as
**`OneMuseum-V0.11-old`** — tags `v0.11` and `v1.0.1` survive only there, not
on the new remote. v1.0.2 is baseline-only: the tree is v1.0.1 plus doc
updates, no app code change.

**Immediate next work** is the D-005 layered plan, in order: **F-008** (dbutils
error surfacing) -> **F-009** (switchable logging) -> **F-010** (test harness,
MathGL-modelled). Anchor case: **B-004** equations-lesson 500 (katex fork).
**Launch blocker:** **B-003** auth bypass (kept for now; must remove + scrub
before public). Bigger parked items (Postgres F-001, containerization F-002,
UI reframe F-003) remain in docs/BACKLOG.md.
