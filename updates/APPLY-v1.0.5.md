# APPLY — v1.0.5 (error handling, admin tooling, live lockdown)

Consolidated record of this increment: what changed, what was verified, what
was not, and the git commands to commit it as the next HEAD.

This session was largely unplanned. It began on the intended v1.0.5 work
(F-013) but became a live-site security response when an open, unprotected
`/signup` route on the production server was found to be accumulating bot
registrations. The live site was taken offline for rebuild. Much of the value
below is therefore findings, not features — recorded so they are not
rediscovered painfully later.

**Scope delivered:** F-013 (DB connection error handling, with tests); a
developer `Makefile`; an admin CLI (`create-user`, `reset-password`,
`check-login`, `list-users`); a signup lockdown (`SIGNUP_ENABLED`, default
closed); database access tooling (`scripts/db.sh`) and its runbook
(`docs/DB-ACCESS.md`); a safe user-wipe script; and the laptop dev database
reset to three known test accounts.

**Live-site actions (production):** `/signup` route body commented out and
redirected; the site was then suspended in Plesk (503). See section 5.

**Deferred:** F-015 (diagnostic logging) — unblocked by F-013, not started.
Technical Reference — not started. Live bot-account cleanup — deferred to the
rebuild (do not run destructive SQL on production; filter on migration
instead).

---

## 1. Files changed

### New

| File | Purpose |
| --- | --- |
| `onemuseum/cli.py` | Admin CLI, registered on `app.cli` (top-level commands). `create-user`, `reset-password`, `check-login`, `list-users`. **In the package** — uses package-relative imports. |
| `Makefile` | **Project root.** Developer command runner. Encodes the port-5001 (AirPlay) and `python -m` findings. Targets: `open`, `create-user`, `reset-password`, `check-login`, `list-users`, `db-shell`, `db-backup`, `db-file`. |
| `scripts/db.sh` | **Project root.** Encodes the one working DB connection (app user, TCP, password from `.env`). Subcommands: `shell`, `query`, `file`, `backup`, `dump`. |
| `docs/DB-ACCESS.md` | Runbook: why DB access was hard, the five traps, backup methods, and the F-014 credential-model implications for the rebuild. |
| `SQL/DEV-wipe-users.sql` | Transaction-wrapped wipe of users + the nine referencing tables. FK column is `UserID` → `users.GUID`. Now commits. **Dev only.** |
| `tests/test_dbutils_connect.py` | 11 tests for F-013. Need no live database (they monkeypatch `mysql.connector.connect`), so they run in CI. |

### Modified

| File | Change |
| --- | --- |
| `onemuseum/dbutils.py` | F-013: `dbOpen()` raises `DBConnectionError` (chaining the driver error as `__cause__`) instead of returning an unassigned `DBCONN`. `dbClose(None)` is now safe and its bare `try/finally` gained the missing `except`. `DBCONN = None` before each of the 13 internal `try` blocks. |
| `onemuseum/config.py` | Adds `SIGNUP_ENABLED` (default **closed**; only truthy `1/true/yes/on` opens it). |
| `onemuseum/users/routes.py` | `signup()` gated on `SIGNUP_ENABLED`, blocking both GET and POST. |
| `.env.example` | Documents `SIGNUP_ENABLED=false`. |

---

## 2. What was verified, and what was not

### Verified
- **F-013** — 11 tests pass against the patched module. Failure modes (bad
  password, missing DB, unreachable host, unmapped errno) all raise
  `DBConnectionError`; the password is never disclosed; the driver error is
  chained; the success path returns the connection unchanged; `dbClose(None)`
  and closing a broken connection are both safe.
- **CLI commands** — all four register at top level (confirmed against a real
  `create_app()`); `check-login` reports correct/wrong/unconfirmed/bypass/
  invalid-hash/no-such-user correctly with meaningful exit codes; the
  clarified test-password prompt renders.
- **`scripts/db.sh`** — the wipe ran through it end to end on the laptop; the
  three test accounts were created and verified with `check-login` and by
  browser sign-in.
- **Backup** — a 9.7 MB volume tarball was taken and its contents listed
  before the wipe.

### Not verified
- **The signup lockdown on the LIVE server.** Applied on the laptop only. On
  live, `/signup` was closed by commenting out the route body directly (see
  section 5), not via `SIGNUP_ENABLED`.
- **F-013 against a live database.** The DB-dependent tests
  (`test_dbutils_01.py`) still need real rows; only the connection-failure
  tests run without a database.
- **Whether the live codebase has the `SIGNUP_ENABLED` gate.** `findstr` was
  not conclusively run; the live route was closed by direct edit instead.

---

## 3. Findings from this session (for BACKLOG.md)

These were discovered incidentally and are the main product of the session.

1. **Unconfirmed accounts can sign in (live).** Session data shows unconfirmed
   bot accounts with session rows. `signin()` does not gate on
   `email_confirmed`. Email confirmation currently protects nothing.
2. **B-003 is broader than recorded.** The hardcoded force-login
   (`roger107@rl.co.za`, `linkmunirih@gmail.com`) exists in **both** `signin()`
   and `signin_reauth()`. It also has a **latent crash**: on an unknown email,
   `user` is `None` and `elif user.email == ...` raises `AttributeError`, so a
   mistyped-email login attempt 500s.
3. **Plaintext passwords in legacy data.** `_TEST_USER`/`test@example.com` and
   `ninalayton` had the literal string `password` in the `Password` column
   (not a bcrypt hash), each with a distinct role GUID — likely part of the
   B-003 mechanism. (Removed in the laptop wipe; still present in the live
   backup.)
4. **Awkward credential model (F-014).** `onemuseum_app` lacks `LOCK TABLES`
   and `SHOW VIEW` (breaks `mysqldump`), is denied over the socket (only TCP
   works), and the container's `MARIADB_ROOT_PASSWORD` is a phantom because the
   volume pre-existed — the real root password is unknown, reachable only via
   unix_socket. Full detail in `docs/DB-ACCESS.md`.
5. **Open `/signup` had no protection.** No CAPTCHA, no rate limit. ~90 of the
   ~100 accounts were bot registrations from `testform.xyz`, `acetylcholgh.ru`,
   and dotted-Gmail variants. A handful of REAL institutional signups existed
   (Collections Trust, several .ac.za / .gov.za addresses) — noted in case
   they matter to the project, though the user chose not to preserve them.

---

## 4. Git — suggested commits

Commit the code **before** applying the doc/backlog edits, so code and
documentation land as separate, readable commits. Grouped by concern:

```
# 1. F-013 + tests
git add onemuseum/dbutils.py tests/test_dbutils_connect.py
git commit -m "F-013: dbOpen raises DBConnectionError instead of masking the cause

Previously dbOpen() caught the connection error, printed it, and fell through
to 'return DBCONN' — never assigned — raising UnboundLocalError that escaped
callers' except clauses and surfaced from finally: dbClose(DBCONN). Now raises
DBConnectionError chaining the driver error; dbClose(None) is safe; DBCONN is
bound before each try. Adds 11 no-database regression tests."

# 2. Signup lockdown
git add onemuseum/config.py onemuseum/users/routes.py .env.example
git commit -m "Close public signup by default (SIGNUP_ENABLED)

/signup now refuses GET and POST unless SIGNUP_ENABLED is explicitly truthy.
Stop-gap against bot registrations on an unprotected form; proper controls
(rate limiting, CAPTCHA, confirmed-email gating) are a later hardening item."

# 3. Admin CLI
git add onemuseum/cli.py onemuseum/__init__.py
git commit -m "Add admin CLI: create-user, reset-password, check-login, list-users

Terminal-only admin commands registered on app.cli, isolated from the web UI.
create-user/reset-password mirror the app's bcrypt path and prompt clearly for
a TEST password. check-login verifies a credential without a session and
reports the true result plus B-003/unconfirmed caveats."

# 4. Dev tooling + runbook
git add Makefile scripts/db.sh docs/DB-ACCESS.md SQL/DEV-wipe-users.sql
git commit -m "Add Makefile, db.sh helper, DB-ACCESS runbook, dev user-wipe script

Encodes the working DB connection and the port/interpreter findings so admin
tasks and backups are one command. DB-ACCESS.md documents the credential traps
for the F-014 rebuild."

# 5. This session's records
git add updates/APPLY-v1.0.5.md updates/HANDOVER-v1.0.5-START.md docs/BACKLOG.md
git commit -m "v1.0.5 session records: APPLY, HANDOVER, backlog findings"
```

Adjust paths if any file is not where this assumes (see the root-vs-package
note: only `cli.py` is inside `onemuseum/`).

---

## 5. Live-changes log (production — FILL IN TIMES)

Every change made to the production server this session, for the record. **The
site is currently OFFLINE by choice.** Timestamps to be completed by the
operator.

| When (SAST) | Change | Reversal |
| --- | --- | --- |
| (prev session) | Added an IIS URL Rewrite rule to block `/signup` | Removed — it 500'd `/signin` |
| ______ | Removed the rewrite rule; `/signin` restored | n/a |
| ______ | Commented out the `signup()` route body; redirect to signin | Uncomment the route |
| ______ | Suspended `onemuseum.net` in Plesk (503 Service Unavailable) | Plesk → domain → **Activate** |

Note also: the live database has NOT been altered — the ~100 accounts and the
plaintext-password rows remain. The 9.7 MB laptop backup is the dev copy only;
a separate live backup should be taken before any rebuild migration.

---

## 6. State at close

- **Live:** offline (Plesk 503). All security exposure parked.
- **Laptop dev DB:** wiped and reset to three confirmed test accounts
  (`roger` / `munirih` / `sholeen`), each verifiable with `make check-login`.
- **Code:** all changes on disk, **not yet committed** (see section 4).
- **Next:** F-015, then the Technical Reference. See
  `HANDOVER-v1.0.5-START.md`.
