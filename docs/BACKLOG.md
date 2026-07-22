# Backlog & Version Plan

The "when / what next". Features **F-nnn**, bugs **B-nnn**, cross-linked to
decisions (**D-nnn**). Status: OPEN · IN-PROGRESS · DONE · PARKED.

---

## Version plan

- **v0.11** — preserved prior working version (the specification / ground truth).
- **v1.0.0** — cleanup & Flask-layout restructure (D-001, D-002).
- **v1.0.1** — + Flask 3 dependency resolution (D-003).
- **v1.0.2** — fresh-repo git baseline; prior GitHub history abandoned
  (archived as `OneMuseum-V0.11-old`); tagged on new remote (D-004). Baseline/
  repo-reset only — no app code change. *This release.*
- **next (the D-005 layered plan, in order):** F-008 dbutils error surfacing
  -> F-009 switchable logging -> F-010 test harness. Each its own increment,
  accepted before coding.
- **v1.x** — small behaviour-preserving increments (asset diet, snippet/POC
  housekeeping).
- **before public launch** — B-003 auth-bypass removal + history scrub;
  F-006 SQL identifier hardening.
- **later minor** — containerization against MariaDB (F-002).
- **later major** — Postgres migration (F-001); UI reframe (F-003). Each its
  own increment.

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

## Security / launch blockers

- **B-003 — hardcoded auth-bypass ("FORCED SIGN IN").** `onemuseum/users/
  routes.py` contains two blocks that log a user in **without a valid
  password** when the email matches a hardcoded address: `signin()` bypasses
  for `roger107@rl.co.za` **or** `linkmunirih@gmail.com`; `signin_reauth()`
  bypasses for `roger107@rl.co.za`. Intentional dev backdoor, not a defect.
  **Roger's ruling (2026-07-22): keep for now.** MUST be removed **and scrubbed
  from git history** before onemuseum.net is "truly available for general use"
  — it is now committed on the public-track repo (v1.0.2), so removal later is
  a history-rewrite, not just a delete. Do not exercise it; remove only when
  asked. Status: **OPEN — deferred by Roger; blocks public launch.**

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
  returns `False` into calling code (half-silent). Methodology §6 prefers a
  clear errors channel over silent fallbacks. **Layer 1 of the D-005 plan —
  the root fix, done first.** Status: **NEXT UP** (D-005).

- **F-009 — switchable logging.** Toggleable verbosity: exception + route +
  SQL/proc + params. Makes failures observable; pairs with F-008. **Layer 2 of
  D-005.** Status: **OPEN** (D-005, after F-008).

- **F-010 — test harness (MathGL-modelled, DB-adapted).** Numbered
  dependency-ordered corpus, mirrored goldens, compare/accept/review runner,
  deliberate acceptance, seeded/pinned determinism, docs-in-step check (have
  `tests/test_config_docs.py`), CI `compare` on push. **Prerequisite:** a
  pinned DB-fixture decision — OneMuseum renders from MariaDB via stored procs,
  so goldens can't be pure file-renders as in MathGL (fixed seed dataset, or
  golden against mocked query results; unit likely = route request vs known DB
  state asserting on rendered HTML). **Layer 3 of D-005, needs F-008 + F-009
  first.** Status: **OPEN** (D-005).

- **B-004 — equations-lesson 500 / katex fork.** Math lessons 500;
  `markdown-katex` needs a native `katex` binary absent on the Mac
  (`NotImplementedError: katex binary not found`); plain lessons render fine.
  Architectural fork — `npm install katex` (native) vs. client-side KaTeX/
  MathJax (check MathGL's approach). The anchor case for the D-005 plan; own
  decision entry when reached — do not one-line. Status: **OPEN**.

---

## Planning inputs awaiting intake

- Workbook scans (much designed work "never installed" — tag each item
  built-and-working / built-not-installed / designed-never-built).
- Screen dumps with per-screen explanation, to align intended vs actual
  behaviour against the code.
