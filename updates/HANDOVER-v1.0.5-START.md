# HANDOVER — v1.0.5 (START)

Outline of the work required for the v1.0.5 increment. Read
`updates/APPLY-v1.0.4.md` first — it records what the previous session
delivered and found, and how v1.0.4 was tagged. This document is
forward-looking: what to pick up, in what order, and why.

Context: the previous session was consumed by an unplanned live-security
response (open `/signup`, bot accounts, taking the production site offline).
The v1.0.4 tag shipped F-013 plus admin tooling and the lockdown. Its third
planned item, **F-015, was deferred to v1.0.5** and is the natural starting
point now — F-013, the error channel it builds on, is done and tested.

---

## 0. Before any feature work

- **Confirm v1.0.4 is committed and tagged** (APPLY-v1.0.4 §4). If not done,
  do it first.
- **Complete the live-changes log** timestamps in APPLY-v1.0.4 §5.
- **Confirm the laptop still runs:** `make open`, sign in as `roger`, and
  `make check-login` for all three test accounts. Five minutes; confirms the
  environment survived.

---

## 1. F-015 — diagnostic logging (the v1.0.5 feature)

The deferred v1.0.4 item, now the head of v1.0.5. Layer 2 of the D-005 plan
(= F-009 in the backlog).

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

## 2. Technical Reference (the wanted document)

Keep the 2025 V2 structure (Technology Architecture, GitHub Repository,
Database Table/Procedure Design, Application Structure, SDF, UI). **Replace the
IIS/wfastcgi runbook** — the legacy production being walked away from — with
the Docker/Compose environment. Pull SDF, architecture, and curriculum
material in *by reference* from the existing docs rather than restating them.

Write now with confidence: Database Table Design, Database Procedure Design
(the `callproc` procedures + `UPLOAD_*` family), Application Structure
(blueprint map), the credential model (F-014 + `docs/DB-ACCESS.md`), and the
admin CLI + Makefile built in v1.0.4. Mark as open: image storage and the
cloud platform. Best done after F-015 exists, since logging is one thing it
should document.

---

## 3. Launch-blockers surfaced in v1.0.4 (schedule deliberately)

Findings from APPLY-v1.0.4 §3, now needing decisions and work. None are urgent
while the site is offline, but all block "truly available for general use."

- **B-005 — authentication is not enforced as it appears.** `signin()` does
  not gate on `email_confirmed`; unconfirmed accounts can log in. Decide
  whether confirmation should gate access, and implement.
- **B-006 — B-003 removal is bigger than "delete two lines."** The bypass is in
  both `signin()` and `signin_reauth()`, and removing it must also fix the
  latent `AttributeError` crash on unknown emails. Needs a history scrub, not
  just deletion.
- **F-016 — registration hardening before `/signup` reopens.** Rate limiting
  (Flask-Limiter), CAPTCHA/Turnstile, confirmed-email gating — the proper
  controls the `SIGNUP_ENABLED` stop-gap stands in for.
- **B-007 / F-014 — credential model.** Investigate the plaintext-password
  rows with B-003. The rebuild should provision a least-privilege, host-scoped
  app user; a separate admin/migration user with `LOCK TABLES` and `SHOW VIEW`;
  and a recorded root password. See `docs/DB-ACCESS.md` § "For the rebuild".

---

## 4. Live-site rebuild (the larger arc)

The production site is offline behind a Plesk 503. Bringing it back is not a
"restart" — it is the rebuild the whole project is aimed at.

- **Bot-account cleanup happens on migration, not on live.** Do NOT run
  destructive SQL against production. When rebuilding, migrate only the real
  accounts (or none) and leave the bots behind. A separate live DB backup must
  be taken first.
- The holding decision — dormant vs maintenance page — is settled for now
  (suspended, 503). Revisit when the rebuild target exists.

---

## 5. Carried-over debt (unchanged)

- Remove `pytest-flask==1.2.0` from `requirements-dev.txt` (breaks under
  Flask 3; no test uses it).
- `docs/BACKLOG.md` / `docs/DEVENV.md` consolidation.
- Never-verified claims: `Dockerfile` never built, `launch.json` never run,
  `docker compose up` never created the container, cold-start never run end to
  end.
- `git filter-repo` for the ~76 MB still in history — cheap now, disruptive
  after a second clone.

---

## Suggested order for v1.0.5

1. Commit + tag v1.0.4, verify the laptop (§0) — protects everything.
2. F-015 (§1) — the feature, now unblocked.
3. Technical Reference (§2) — after F-015, so logging can be documented.
4. Then pick from the launch-blockers (§3) as priority allows.

The launch-blockers (§3) and rebuild (§4) are larger arcs that want deliberate
decisions — ideally with the second developer — not a rushed pass. The
concrete, do-it-now work is F-015 and the Technical Reference.
