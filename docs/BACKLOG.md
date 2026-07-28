# Backlog & Version Plan

The "when / what next". Features **F-nnn**, bugs **B-nnn**, cross-linked to
decisions (**D-nnn**). Status: OPEN · IN-PROGRESS · DONE · PARKED.

**How this file works.** The **Index** below lists *every* ID ever assigned
(open and done) so numbers are never reused — done items show their version and
point to `BACKLOG-archive.md` for detail. Only **open** items are detailed in
full, further down. Priority: **P1** launch-blocker · **P2** next feature work ·
**P3** parked / later.

- **Next free numbers:** **F-028**, **B-009**.
- **Current version:** v1.0.5 (in progress).
- **v1.0.5 focus:** F-017 (version string) done. F-018 (email confirmation)
  designed, paused for the Munirih session. F-015 (diagnostic logging)
  deferred to next version (extend `SessionLog` rather than write new).
- **The month ahead (P2):** F-019–F-024 — content, admin, filters, curriculum,
  inventory, Chenhall. See detail. *OneMuseumIngestor is a separate app
  (`ingest.onemuseum.net`), tracked in its own repo — not an F-item here.*

---

## Index — all items

### Features

| ID | Title | Pri | Target | Status |
|------|-------|-----|--------|--------|
| F-001 | Postgres migration | P3 | later major | PARKED |
| F-002 | Containerization against MariaDB | P3 | later minor | PARKED |
| F-003 | UI reframe / retheme | P3 | later major | PARKED |
| F-004 | Unused-asset diet | P3 | v1.x | PARKED |
| F-005 | Requirements runtime/dev split | — | v1.0.1 | DONE → archive |
| F-006 | SQL identifier hardening | P1 | before launch | OPEN |
| F-007 | Snippet / POC housekeeping | P3 | v1.x | PARKED |
| F-008 | dbutils error surfacing (D-005 L1) | P2 | — | DONE via F-013 |
| F-009 | Switchable logging (D-005 L2) | P2 | v1.0.5 | = F-015 |
| F-010 | Test harness (D-005 L3) | P2 | later | OPEN |
| F-013 | dbutils connection error surfacing | P2 | v1.0.5 | DONE → archive |
| F-014 | Credential-model rebuild | P2 | before launch | OPEN |
| F-015 | Diagnostic logging (operational, `diaglog.py`) | P2 | v1.0.5 | DONE |
| F-016 | Registration hardening before signup reopens | P1 | before launch | OPEN |
| F-017 | Dynamic version string on every page | P2 | v1.0.5 | DONE → archive |
| F-018 | Mandatory email confirmation (hard-block) | P1 | this month | OPEN — paused |
| F-019 | Museum content development (customer museums) | P2 | this month | OPEN |
| F-020 | Admin facilities + admin access control (D-007) | P2 | this month | OPEN |
| F-021 | Filter linkages working (5 filters) | P2 | this month | OPEN |
| F-022 | Curriculum structures (CAPS educator access) | P2 | this month | OPEN |
| F-023 | National museum + collection inventory | P2 | this month | OPEN |
| F-024 | Chenhall core filter + directory update | P2 | this month | OPEN |
| F-025 | Archive completed `updates/` session files | P3 | housekeeping | OPEN |
| F-026 | Reconcile stale `docs/DECISIONS.md` vs `updates/` | P3 | housekeeping | OPEN |
| F-027 | Amendment Register — audit trail of all data changes | P2 | before launch | OPEN |

### Bugs

| ID | Title | Pri | Target | Status |
|------|-------|-----|--------|--------|
| B-001 | `dbUpdate` called `dbClose()` not `dbOpen()` | — | v1.0.0 | DONE → archive |
| B-002 | `test_menus` uses `.items` not `.items()` | P3 | — | OPEN (test-only) |
| B-003 | Hardcoded auth-bypass ("FORCED SIGN IN") | P1 | before launch | OPEN — deferred |
| B-004 | equations-lesson 500 / katex fork | P2 | — | OPEN |
| B-005 | Unconfirmed accounts can sign in | P1 | before launch | OPEN |
| B-006 | B-003 bypass broader + crashes (AttributeError) | P1 | before launch | OPEN |
| B-007 | Plaintext passwords in legacy data | P2 | before launch | OPEN |
| B-008 | dbutils_01/02 tests assert pre-wipe seed data | P3 | — | OPEN (test-only) |

---

## Version plan

- **v0.11** — preserved prior working version (specification / ground truth).
- **v1.0.0** — cleanup & Flask-layout restructure (D-001, D-002).
- **v1.0.1** — Flask 3 dependency resolution (D-003).
- **v1.0.2** — fresh-repo git baseline; prior GitHub history abandoned
  (archived as `OneMuseum-V0.11-old`); tagged on new remote (D-004).
- **v1.0.4** — F-013 error handling, admin CLI, signup lockdown, dev DB
  tooling. Tagged `v1.0.4`.
- **v1.0.5** *(in progress)* — F-017 version string (done); **F-015**
  diagnostic logging + Technical Reference (the D-005 Layer-2 work).
- **before public launch (P1 gate)** — B-003 auth-bypass removal + history
  scrub; B-005 / B-006 (fold into B-003 removal); F-016 registration
  hardening; F-006 SQL identifier hardening.
- **later minor** — F-002 containerization against MariaDB.
- **later major** — F-001 Postgres migration; F-003 UI reframe. Each its own
  increment.

---

## Open items — detail

### Security / launch blockers (P1)

- **B-003 — hardcoded auth-bypass ("FORCED SIGN IN").** `onemuseum/users/
  routes.py` contains two blocks that log a user in **without a valid
  password** when the email matches a hardcoded address: `signin()` bypasses
  for two hardcoded addresses; `signin_reauth()` bypasses for one. Intentional
  dev backdoor, not a defect. **Roger's ruling (2026-07-22): keep for now.**
  MUST be removed **and scrubbed from git history** before onemuseum.net is
  "truly available for general use" — it is committed on the public-track repo
  (v1.0.2), so removal later is a history-rewrite, not just a delete. Do not
  exercise it; remove only when asked. Status: **OPEN — deferred by Roger;
  blocks public launch.**

- **B-005 — unconfirmed accounts can sign in.** `signin()` does not gate on
  `email_confirmed`; live session data showed unconfirmed bot accounts with
  sessions. Email confirmation currently protects nothing. Status: **OPEN.**

- **B-006 — B-003 bypass is broader + crashes.** The hardcoded force-login is
  in **both** `signin()` and `signin_reauth()`. On an unknown email, `user` is
  `None` and `elif user.email == ...` raises `AttributeError` (login attempt
  500s). Fold into B-003 removal. Status: **OPEN.**

- **F-016 — registration hardening before `/signup` reopens.** Open `/signup`
  had no CAPTCHA or rate limit; ~90 bot signups resulted. Closed for now via
  `SIGNUP_ENABLED` (default off) on the laptop and by route edit on live.
  Proper controls: rate limiting, CAPTCHA/Turnstile, confirmed-email gating.
  Status: **OPEN.**

- **F-006 — SQL identifier-interpolation hardening.** Several `dbutils`
  helpers f-string table/field names into SQL (`dbExists`, `dbGetRow`,
  `dbInsert`, browser LIMIT/OFFSET). Values are parameterised; identifiers are
  not. Low risk while single-authored + behind login; matters once "truly
  available for general use". Status: **OPEN** (P1 gate).

### Email confirmation (P1, this month)

- **F-018 — mandatory email confirmation, hard-block.** The confirmation
  machinery is complete and wired: `signup()` sends a tokenised email
  (Flask-Mail; `mail` initialised in `__init__`; `MAIL_*` from env),
  `/confirm/<token>` verifies (itsdangerous, 30-min salted token) and sets
  `email_confirmed`, `/resend_email_confirmation` re-sends. What's missing is
  enforcement + a transport. **Decisions (Roger):** every new user MUST confirm
  before being allowed to continue (standard practice); **hard-block**, no
  restricted-access tier (not available; possible future access levels noted,
  not now); confirmation is **permanent** — never re-verified, so a later
  provider switch costs nothing. **Scope:** (1) gate `signin()` on
  `email_confirmed`, block if false [absorbs **B-005**]; (2) error-handling on
  the background send thread so a failed send is logged, not swallowed;
  (3) signin-while-unconfirmed UX — message + resend link, not a dead end;
  (4) transport: **Brevo** free tier (300/day, permanent) as the SMTP relay,
  SPF/DKIM at GoDaddy DNS. **Status: OPEN — designed; paused for the Munirih
  session (email + DNS to be set up together). Interacts with B-006, F-016.**

### The month ahead (P2, ~next 4 weeks)

*Content/data/product work, mostly beyond single-increment Flask changes.
Grouped here so the month's intent is visible; each will spawn finer F-items
as it's scoped.*

- **F-019 — museum content development.** Develop useful, valuable content from
  selected customer museums (several already engaged). Curation/data work;
  feeds the app via the Ingestor (separate app). Status: **OPEN.**

- **F-020 — admin facilities + administrator access control.** Admin-only
  facilities, including determining *who* has access to administrator services.
  Lands in this repo; extends the existing admin CLI. First concrete instance
  of the deferred "access levels" question. **Fills D-007 (User access control
  — placeholder, scope to be defined) in `updates/DECISIONS.md`.** Status:
  **OPEN.**

- **F-021 — filter linkages working.** Ensure all linkages to the filters
  (places, times, persons, organisations, subjects) work end to end. In-repo,
  testable. Status: **OPEN.**

- **F-022 — curriculum structures.** Finalise the CAPS-aligned curriculum
  structures — core to educator access to trusted research materials. Part
  data-model, part content. Status: **OPEN.**

- **F-023 — national museum + collection inventory.** Build a complete list of
  all museums in the country and the collections they hold; categorise those
  collections by the five filters (places/times/persons/organisations/
  subjects). Large data-gathering + classification effort. Status: **OPEN.**

- **F-024 — Chenhall as core filter + directory update.** Link Chenhall in as a
  core filter and update the Chenhall directory (~4 years out of date).
  Bridges institutional nomenclature to how teachers search. Status: **OPEN.**

### Deferred to next version (P2)

- **F-015 — diagnostic logging. DONE (v1.0.5).** Built as a standalone `onemuseum` logger (`diaglog.py`), not an extension of `sessiondata`: that table tracks user behaviour (pages, searches, results), a different concern from operational diagnostics (exceptions, DB outages, failing queries). Errors always logged; `DIAG_LOGGING` gates verbose detail; stream destination by config. See D-008.

- **F-014 — credential-model rebuild.** `onemuseum_app` lacks `LOCK TABLES` /
  `SHOW VIEW`; socket vs TCP are different grants; the container root password
  is a phantom (volume pre-existed). Full detail and rebuild guidance in
  `docs/DB-ACCESS.md`. Also covers **B-007 — plaintext passwords in legacy
  data** (`_TEST_USER` and `ninalayton` stored the literal `password`, not a
  bcrypt hash, with distinct role GUIDs — likely part of the B-003 mechanism;
  present in live DB, removed in the laptop wipe). Status: **OPEN.**

- **F-010 — test harness (MathGL-modelled, DB-adapted).** Numbered
  dependency-ordered corpus, mirrored goldens, compare/accept/review runner,
  deliberate acceptance, seeded/pinned determinism, docs-in-step check (have
  `tests/test_config_docs.py`), CI `compare` on push. **Prerequisite:** a
  pinned DB-fixture decision — OneMuseum renders from MariaDB via stored procs,
  so goldens can't be pure file-renders as in MathGL. **Layer 3 of D-005; needs
  F-013 + F-015 first.** Status: **OPEN.**

- **B-004 — equations-lesson 500 / katex fork.** Math lessons 500;
  `markdown-katex` needs a native `katex` binary absent on the Mac
  (`NotImplementedError: katex binary not found`); plain lessons render fine.
  Architectural fork — `npm install katex` (native) vs. client-side KaTeX/
  MathJax. The anchor case for the D-005 plan; gets its own decision entry when
  reached — do not one-line. Status: **OPEN.**

### Parked / later (P3)

- **F-001 — Postgres migration.** Swap `mysql.connector` → `psycopg` in
  `dbutils.py`. Real work is the four runtime stored procedures called via
  `callproc`: `GenDetails`, `ChenhallDetails`, `GenCategories`,
  `UserEntityFavourite` — rewrite as Postgres functions or lift into app SQL.
  Status: **PARKED.**

- **F-002 — Containerization against MariaDB.** Replace the VS Code scaffold
  Dockerfile (python:3.8 EOL, wrong requirements). Add compose with app +
  MariaDB + volume. Prove identical behaviour in-container *before* touching
  the database. Status: **PARKED.**

- **F-003 — UI reframe / retheme.** Current UI: Now UI Kit Pro v1.3.1
  (Creative Tim, 2019; Bootstrap 4). Preserve through v1; reframe is a later
  deliberate increment. Moving toward home-grown CSS rather than another vendor
  theme. Status: **PARKED.**

- **F-004 — Unused-asset diet.** `static/assets` demo imagery largely unused;
  confirm template references before deleting (behaviour risk). Its own
  increment. (Note: ~76 MB of Now UI Kit PRO assets already removed in an
  earlier cleanup.) Status: **PARKED.**

- **F-007 — Snippet / POC housekeeping.** `onemuseum/snippets/` is scratch
  (not imported; one file has a pre-existing harmless syntax error). `pocs/`
  IS a registered blueprint so it ships. Decide what to prune. Status:
  **PARKED.**

- **F-025 — archive completed `updates/` session files.** `updates/` holds 14
  files; most are historical session records (APPLY-v1.0.3, CHANGES-v1.0.1/2,
  HANDOVER-v1.0.1…v1.0.4) that are done and now just noise. Move completed
  handover/apply/changes files aside (e.g. `updates/archive/`), leaving only
  the active increment — mirrors the BACKLOG → BACKLOG-archive split. Do with a
  clear head, not mid-flow. Status: **OPEN (housekeeping).**

- **F-026 — reconcile stale `docs/DECISIONS.md`.** Two decision logs exist:
  `updates/DECISIONS.md` is current (D-001…D-007); `docs/DECISIONS.md` is stale
  (stops at D-005). Not a true duplicate — one is simply behind. Decide the
  single canonical location and remove/redirect the other so there's one
  decisions log. Status: **OPEN (housekeeping).**

  - **F-027 — Amendment Register (audit trail).** A generic change-log trapping every INSERT/UPDATE/DELETE across all tables — old/new values, table, row, user, timestamp — per Roger's standard practice on every schema. Confirmed absent from `onemuseum2` (2026-07-28): no audit/history/amendment table among the 89 tables, and SHOW TRIGGERS is empty. Likely lost in the fresh-repo rebuild (D-004) or never carried over. Design questions for its own increment: (a) implementation — DB triggers (automatic, DB-level) vs logging inside the four stored procs (GenDetails, ChenhallDetails, GenCategories, UserEntityFavourite) vs app-level; (b) how it survives the eventual Postgres migration (F-001); (c) retention/query model. Distinct from sessiondata (user behaviour) and `diaglog.py` (operational diagnostics). Matters before "general use." Status: **OPEN.**

- **B-002 — `test_menus` reference bug.** `tests/test_spec_sdf.py::test_menus`
  references `menu_spec.items` (the built-in method object) instead of
  `menu_spec.items()` / iterating keys, causing `TypeError`. Pre-existing (in
  v0.11); test-only, app code unaffected. Status: **OPEN.**

- **B-008 — dbutils_01/02 tests assert against pre-wipe seed data.**
  `test_exists_11` and `test_getrow` look up user GUID
  `217B6299-…-935EAA1995FC`; `test_exists_31` looks up username `TESTUSER`.
  None exist after the v1.0.4 dev-DB wipe/reset to three test accounts, so
  `dbExists` returns `False` and `dbGetRow` returns an empty row
  (`KeyError: 0`). App code correct; tests coupled to deleted fixtures. Fix:
  reseed, repoint at a known account, or rewrite as self-contained
  create-then-query tests. Test-only; not critical. Status: **OPEN.**

---

## Planning inputs awaiting intake

- Workbook scans (much designed work "never installed" — tag each item
  built-and-working / built-not-installed / designed-never-built).
- Screen dumps with per-screen explanation, to align intended vs actual
  behaviour against the code.
