# HANDOVER — v1.0.5 (START)

Outline of the work required next session. Read `updates/APPLY-v1.0.5.md`
first — it records what the previous session did and found. This document is
forward-looking: what to pick up, in what order, and why.

The previous session was consumed by an unplanned live-security response (open
`/signup`, bot accounts, taking the production site offline). The deliberate
v1.0.5 features barely started. The good news: the incidental findings are
now recorded, and F-013 — the error channel everything else reports through —
is done and tested.

---

## 0. Before any feature work

- **Commit last session's changes** if not already done — see APPLY §4. They
  are on disk but uncommitted.
- **Complete the live-changes log** timestamps in APPLY §5.
- **Confirm the laptop still runs:** `make open`, sign in as `roger`, and
  `make check-login` for all three test accounts. Five minutes; confirms the
  environment survived.

---

## 1. F-015 — diagnostic logging (the main feature)

The planned v1.0.5 item, now unblocked by F-013. Layer 2 of the D-005 plan.

- **Goal:** toggleable diagnostic logging — exception + route + SQL/proc +
  params — so failures are diagnosable without code spelunking.
- **Build it on `DBConnectionError`.** F-013 gave database failures a clean,
  named exception with the driver error chained. F-015's logging should hang
  off that rather than re-inventing error capture.
- **Open decision it forces:** `dbOpen()` now *raises* where it once returned
  a broken value, so `categories/routes.py` and three sites in
  `entities/routes.py` will propagate to Flask's error handler (a 500 with a
  real traceback). F-015 should decide whether a DB outage renders a proper
  error page or re-raises — and log it either way.
- Document the toggle and format in `docs/` as part of the same increment; the
  logging is one of the things the Technical Reference should describe.

---

## 2. Technical Reference (the main document)

Wanted deliverable. Keep the 2025 V2 structure (Technology Architecture,
GitHub Repository, Database Table/Procedure Design, Application Structure, SDF,
UI). **Replace the IIS/wfastcgi runbook** — the legacy production being walked
away from — with the Docker/Compose environment. Pull SDF, architecture, and
curriculum material in *by reference* from the existing docs rather than
restating them.

Write now with confidence: Database Table Design, Database Procedure Design
(the `callproc` procedures + `UPLOAD_*` family), Application Structure
(blueprint map), the credential model (F-014 + `docs/DB-ACCESS.md`), and the
admin CLI + Makefile just built. Mark as open: image storage and the cloud
platform. Best done after F-015 exists, since logging is one thing it should
document.

---

## 3. Launch-blockers surfaced this session (schedule deliberately)

These are findings from APPLY §3, now needing decisions and work. None are
urgent while the site is offline, but all block "truly available for general
use."

- **Authentication is not enforced as it appears.** `signin()` does not gate
  on `email_confirmed` — unconfirmed accounts can log in. Decide whether
  confirmation should gate access, and implement.
- **B-003 removal is bigger than "delete two lines."** The bypass is in both
  `signin()` and `signin_reauth()`, and removing it must also fix the latent
  `AttributeError` crash on unknown emails (`user` is `None`). Needs a history
  scrub, not just deletion. Still a launch-blocker.
- **Registration hardening before `/signup` reopens.** Rate limiting
  (Flask-Limiter), a CAPTCHA/Turnstile, and confirmed-email gating — the
  proper controls the `SIGNUP_ENABLED` stop-gap stands in for.
- **Credential model (F-014).** Rebuild should provision a least-privilege,
  host-scoped app user; a separate admin/migration user with `LOCK TABLES`
  and `SHOW VIEW`; and a recorded root password. See `docs/DB-ACCESS.md` §
  "For the rebuild."

---

## 4. Live-site rebuild (the larger arc)

The production site is offline behind a Plesk 503. Bringing it back is not a
"restart" — it is the rebuild the whole project is aimed at.

- **Bot-account cleanup happens on migration, not on live.** Do NOT run
  destructive SQL against production. When rebuilding, migrate only the real
  accounts (or none) and leave the bots behind. A separate live DB backup must
  be taken before any migration.
- The holding decision — dormant vs maintenance page — is settled for now
  (suspended, 503). Revisit when the rebuild target exists.

---

## 5. Carried-over debt (unchanged from v1.0.4)

Still open, still worth closing:

- Remove `pytest-flask==1.2.0` from `requirements-dev.txt` (breaks under
  Flask 3; no test uses it).
- `docs/BACKLOG.md` / `docs/DEVENV.md` consolidation — the F-0nn items and
  cold-start findings should live in the backlog, not only in handovers.
- The never-verified claims: `Dockerfile` never built, `launch.json` never
  run, `docker compose up` never created the container, cold-start never run
  end to end.
- `git filter-repo` for the ~76 MB still in history — cheap now, disruptive
  after a second clone.

---

## Suggested order for next session

1. Commit + verify (§0) — 15 min, protects everything.
2. F-015 (§1) — the actual feature, now unblocked.
3. Technical Reference (§2) — after F-015, so logging can be documented.
4. Then pick from the launch-blockers (§3) as time and priority allow.

The launch-blockers (§3) and rebuild (§4) are larger arcs that want deliberate
decisions — ideally with the second developer — not a rushed pass. The
concrete, do-it-now work is F-015 and the Technical Reference.
