# APPLY — v1.0.4 (error handling, admin tooling, live lockdown)

Consolidated record of this increment: what changed, what was verified, what
was not, and the git commands to commit and tag it. This is the close-out for
the **v1.0.4** tag. The forward-looking plan for the next increment is in
`HANDOVER-v1.0.5-START.md`.

This session was largely unplanned. It began on the intended v1.0.4 work
(F-013) but became a live-site security response when an open, unprotected
`/signup` route on the production server was found to be accumulating bot
registrations. The live site was taken offline for rebuild. Much of the value
below is therefore findings, not features — recorded so they are not
rediscovered painfully later.

**Scope delivered (v1.0.4):** F-013 (DB connection error handling, with
tests); a developer `Makefile`; an admin CLI (`create-user`, `reset-password`,
`check-login`, `list-users`); a signup lockdown (`SIGNUP_ENABLED`, default
closed); database access tooling (`scripts/db.sh`) and its runbook
(`docs/DB-ACCESS.md`); a safe user-wipe script; and the laptop dev database
reset to three known test accounts.

**Live-site actions (production):** `/signup` route body commented out and
redirected; the site was then suspended in Plesk (503). See section 5.

**Deferred to v1.0.5:** F-015 (diagnostic logging) — the third v1.0.4-planned
item, unblocked by F-013 but not started. Technical Reference — not started.
Live bot-account cleanup — deferred to the rebuild (do not run destructive SQL
on production; filter on migration instead).

---

## 1. Files changed

### New

| File | Purpose |
| --- | --- |
| `onemuseum/cli.py` | Admin CLI, registered on `app.cli` (top-level commands). `create-user`, `reset-password`, `check-login`, `list-users`. **In the package** — uses package-relative imports. |
| `Makefile` | **Project root.** Developer command runner. Encodes the port-5001 (AirPlay) and `python -m` findings. Targets: `open`, `create-user`, `reset-password`, `check-login`, `list-users`, `db-shell`, `db-backup`, `db-file`. |
| `scripts/db.sh` | **Project root.** Encodes the one working DB connection (app user, TCP, password from `.env`). Subcommands: `shell`, `query`, `file`, `backup`, `dump`. |
| `docs/DB-ACCESS.md` | Runbook: why DB access was hard, the five traps, backup methods, and the F-014 credential-model implications for the rebuild. |
| `SQL/DEV-wipe-users.sql` | Transaction-wrapped wipe of users + the nine referencing tables. FK column is `UserID` → `users.GUID`. Commits at the end. **Dev only.** |
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

---

## 3. Findings from this session (recorded in BACKLOG.md)

These were discovered incidentally and are the main product of the session.
Tracked as B-005/B-006/B-007/F-016 in `docs/BACKLOG.md`.

1. **Unconfirmed accounts can sign in (live).** `signin()` does not gate on
   `email_confirmed`; session data shows unconfirmed bot accounts with session
   rows. Email confirmation currently protects nothing. (**B-005**)
2. **B-003 is broader than recorded.** The hardcoded force-login
   (`roger107@rl.co.za`, `linkmunirih@gmail.com`) exists in **both** `signin()`
   and `signin_reauth()`, and has a latent crash: on an unknown email, `user`
   is `None` and `elif user.email == ...` raises `AttributeError` (a login
   attempt 500s). (**B-006**)
3. **Plaintext passwords in legacy data.** `_TEST_USER`/`test@example.com` and
   `ninalayton` had the literal string `password` in `Password` (not a bcrypt
   hash), each with a distinct role GUID — likely part of the B-003 mechanism.
   Removed in the laptop wipe; still present in the live backup. (**B-007**)
4. **Awkward credential model (F-014).** `onemuseum_app` lacks `LOCK TABLES`
   and `SHOW VIEW`; is denied over the socket (only TCP works); the container's
   `MARIADB_ROOT_PASSWORD` is a phantom because the volume pre-existed. Full
   detail in `docs/DB-ACCESS.md`.
5. **Open `/signup` had no protection.** No CAPTCHA, no rate limit. ~90 of the
   ~100 accounts were bot registrations. A handful of REAL institutional
   signups existed (Collections Trust, several .ac.za / .gov.za addresses) —
   noted in case they matter, though the user chose not to preserve them.
   (**F-016**)

---

## 4. Git — commit and tag

Commit the code before the docs, so they land as separate, readable commits.
The default below is **two commits** (code, then docs); split further only if
you want granular history.

```
# 1. Code
git add onemuseum/ Makefile scripts/ SQL/DEV-wipe-users.sql tests/
git commit -m "v1.0.4: F-013 error handling, admin CLI, signup lockdown, dev DB tooling

F-013: dbOpen() raises DBConnectionError instead of returning an unassigned
DBCONN (which raised UnboundLocalError and masked the real cause). dbClose(None)
safe; DBCONN bound before each try; 11 no-database regression tests.
Signup lockdown: /signup refuses GET and POST unless SIGNUP_ENABLED is truthy.
Admin CLI (create-user, reset-password, check-login, list-users), Makefile,
scripts/db.sh + DB-ACCESS runbook, dev user-wipe script."

# 2. Session records
git add updates/APPLY-v1.0.4.md updates/HANDOVER-v1.0.5-START.md docs/BACKLOG.md
git commit -m "v1.0.4 session records: APPLY, v1.0.5 handover, backlog findings"

# 3. Tag the release (annotated) and push branch + tag
git tag -a v1.0.4 -m "v1.0.4: F-013 error handling, admin CLI, signup lockdown, dev DB tooling"
git push origin HEAD --follow-tags
```

Before running: `git status` (clean tree), `git log --oneline -5` (commits
present), `git tag` (v1.0.3 is the previous), `git remote -v` and
`git branch --show-current` (confirm remote name and branch). Only `cli.py` is
inside `onemuseum/`; the Makefile, scripts, SQL, and docs are at root/their
folders.

---

## 5. Live-changes log (production — FILL IN TIMES)

Every change made to the production server, for the record. **The site is
currently OFFLINE by choice.** Timestamps to be completed by the operator.

| When (SAST) | Change | Reversal |
| --- | --- | --- |
| (prev session) | Added an IIS URL Rewrite rule to block `/signup` | Removed — it 500'd `/signin` |
| ______ | Removed the rewrite rule; `/signin` restored | n/a |
| ______ | Commented out the `signup()` route body; redirect to signin | Uncomment the route |
| ______ | Suspended `onemuseum.net` in Plesk (503 Service Unavailable) | Plesk → domain → **Activate** |

The live database has NOT been altered — the ~100 accounts and the
plaintext-password rows remain. The 9.7 MB laptop backup is the dev copy only;
a separate live backup must be taken before any rebuild migration.

---

## 6. State at close

- **Live:** offline (Plesk 503). All security exposure parked.
- **Laptop dev DB:** wiped and reset to three confirmed test accounts
  (`roger` / `munirih` / `sholeen`), each verifiable with `make check-login`.
- **Code:** all changes on disk; commit and tag per section 4.
- **Next:** F-015, then the Technical Reference. See
  `HANDOVER-v1.0.5-START.md`.
