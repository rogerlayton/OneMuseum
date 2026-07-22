# Backlog & Version Plan

The "when / what next". Features **F-nnn**, bugs **B-nnn**, cross-linked to
decisions (**D-nnn**). Status: OPEN · IN-PROGRESS · DONE · PARKED.

---

## Version plan

- **v0.11** — preserved prior working version (the specification / ground truth).
- **v1.0.0** — cleanup & Flask-layout restructure (D-001, D-002).
- **v1.0.1** — + Flask 3 dependency resolution (D-003). *This release.*
- **v1.x** — small behaviour-preserving increments (asset diet, dev/runtime
  requirements split hardening, snippet/POC housekeeping).
- **later minor** — containerization against MariaDB.
- **later major** — Postgres migration; UI reframe. Each its own increment.

---

## Bugs

- **B-001** — `dbUpdate` called `dbClose()` instead of `dbOpen()`; failed on
  every call. *Fixed in v1.0.0 (D-001).* Status: **DONE**. Roger to confirm
  any live code path through `dbUpdate` now behaves as intended.

---

- **B-002** — `tests/test_spec_sdf.py::test_menus` references `menu_spec.items`
  (the built-in method object) instead of `menu_spec.items()` / iterating keys,
  causing `TypeError`. Pre-existing (present in v0.11); exposed once the SDF
  loader path was fixed (D-002). Test-only; app code unaffected. Status:
  **OPEN**.

## Features / tasks (parked unless noted)

- **F-001 — Postgres migration.** Swap `mysql.connector` -> `psycopg` in
  `dbutils.py` (contained to ~1 file + 2 stray imports). Real work is the four
  runtime stored procedures called via `callproc`: `GenDetails`,
  `ChenhallDetails`, `GenCategories`, `UserEntityFavourite` — rewrite as
  Postgres functions or lift into app SQL. Need the MariaDB data model + those
  proc bodies at that point. Status: **PARKED**.

- **F-002 — Containerization against MariaDB.** Replace the VS Code scaffold
  Dockerfile (python:3.8 EOL, installs wrong requirements). Add compose with
  app + MariaDB + volume. Prove identical behaviour in-container *before*
  touching the database. Status: **PARKED**.

- **F-003 — UI reframe / retheme.** Current UI: **Now UI Kit Pro v1.3.1**
  (Creative Tim, 2019; Bootstrap 4). Preserve current UI through v1; reframe
  is a later deliberate increment. Workbook scans + screen dumps to feed this.
  Status: **PARKED**.

- **F-004 — Unused-asset diet.** `static/assets` is ~74 MB, of which ~71 MB is
  the kit's demo imagery (`img/presentation-page` 23 MB, `img/examples`,
  multi-MB `projectNN.jpg`, hero/iphone/ipad marketing images). Almost
  certainly unused. Must confirm which assets templates reference before
  deleting (behaviour risk). Its own increment. Status: **PARKED**.

- **F-005 — Requirements runtime/dev split.** v1.0.0 split runtime/dev;
  v1.0.1 resolved the Flask/Werkzeug clash by bumping Flask 2.2.2->3.1.3 and
  Flask-Login 0.6.2->0.6.3, Flask-WTF->1.2.2 (D-003). `pywin32` stays dev-only
  (Windows). Status: **DONE** (v1.0.1).

- **F-006 — SQL identifier-interpolation hardening.** Several `dbutils`
  helpers f-string table/field names into SQL (`dbExists`, `dbGetRow`,
  `dbInsert`, browser LIMIT/OFFSET). Values are parameterised; identifiers are
  not. Low risk while single-authored + behind login; matters once "truly
  available for general use". Status: **PARKED**.

- **F-007 — Snippet / POC housekeeping.** `onemuseum/snippets/` is scratch
  (not imported; one file has a pre-existing syntax error, harmless). `pocs/`
  IS a registered blueprint so it ships. Decide what to prune. Status:
  **PARKED**.

- **F-008 — dbutils error surfacing.** DB layer flashes errors to the UI and
  returns `False` into calling code (half-silent). Methodology prefers a clear
  errors channel over fallbacks. Status: **PARKED**.

---

## Planning inputs awaiting intake

- Workbook scans (much designed work "never installed" — tag each item
  built-and-working / built-not-installed / designed-never-built).
- Screen dumps with per-screen explanation, to align intended vs actual
  behaviour against the code.
