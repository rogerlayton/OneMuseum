# APPLY — v1.0.5 (F-018 email confirmation: transport, sign-in gate, hardening)

Consolidated record of this increment: what changed, what was verified, what
was not, and the git commands to commit it. This is a **separate increment**
from `APPLY-v1.0.5.md` (which covered F-013, admin tooling, and the security
lockdown) — it is not a replacement for that file.

This session took F-018 (mandatory email confirmation) from "machinery exists
but enforces nothing" to "confirmation proven end to end and enforced at
sign-in." It also closes **B-005** (unconfirmed accounts could sign in),
originally recorded as finding #1 of the previous v1.0.5 session.

**Scope delivered:** Brevo SMTP transport configured and proven (email confirmation
delivered to a real inbox); the `email_confirmed` sign-in gate (absorbs B-005);
send-failure logging across all three mail sites (via F-015 `diaglog`); a
self-sufficient gate test suite; a `doctor.py` mail check; and an Email Handling
chapter for the Technical Reference.

**Deferred / surfaced (not fixed this increment):** public resend-by-email route
(proposed **F-029**); `send_reset_email()` uses an unconfigured `Mail()` — password
reset email is broken (proposed **B-010**); DKIM/SPF domain authentication for
`onemuseum.net` at GoDaddy (status unverified — see section 2); base-URL of the
confirm link should be config-driven rather than hand-set.

---

## 1. Files changed

### New

| File | Purpose |
| --- | --- |
| `tests/test_signin_gate.py` | Four tests for the F-018 sign-in gate. **Self-sufficient** — a local `_TestConfig(Config)` supplies dummy settings so they run with no `.env` and no database (the user lookup is monkeypatched). Verified: unconfirmed blocked, `None`-flag blocked, confirmed passes, wrong password never reaches the gate. |
| `docs/TECHREF-email-handling.md` | Technical Reference — Email Handling chapter. Config, send path, confirmation flow, the dev/prod base-URL trap, testing recipes, the password-reset bug, and the hard-won traps (Brevo authorised-IP, "Sent ≠ Delivered", DKIM/SPF status, shell-is-not-a-server, port 5001, `db.sh` grammar). |
| `updates/APPLY-v1.0.5-F018.md` | This document. |
| `updates/NOTE-F018-brevo-transport-proven.md` | Working-state marker written mid-session when transport was first proven; superseded by this APPLY. Optional to keep. |

### Modified

| File | Change |
| --- | --- |
| `onemuseum/users/routes.py` | **F-018 gate:** `signin()` blocks login when `user.email_confirmed` is falsy (checked inside the password-success branch, above `login_user`). **Send hardening:** the two threaded `send_email()` closures (`signup`, `resend_email_confirmation`) wrap `mail.send()` in try/except → `diaglog.log_error`. Import of `log_error` added. The B-003/B-006 FORCED SIGN IN bypass is **untouched**. |
| `onemuseum/users/utils.py` | **Send hardening:** `send_reset_email()` wraps `mail.send(msg)` in try/except → `log_error`. Import added. (The unconfigured `mail = Mail()` bug is left in place — proposed B-010.) |
| `doctor.py` | Adds `check_mail()` (section 7): confirms `MAIL_SERVER/USERNAME/PASSWORD` present (never printing the secret) and does a **TCP-only** connect to `MAIL_SERVER:587` to prove reachability without authenticating (so it cannot trip Brevo's authorised-IP protection). KaTeX renumbered to section 8. |

### Configuration (not code — done in Brevo / .env, for the record)

- Brevo account created; SMTP relay `smtp-relay.brevo.com:587`; SMTP key stored in
  Norton; `.env` MAIL_* populated.
- Verified sender `noreply@onemuseum.net` set up in Brevo.
- Sending IP(s) authorised in Brevo after `525 Unauthorized IP` (see section 3).

---

## 2. What was verified, and what was not

### Verified
- **Transport, end to end.** A real confirmation email ("OneMuseum - Confirm Your
  Email Address", from `noreply@onemuseum.net`) was delivered to a real inbox and
  showed **Delivered** behaviour (arrived, not spam) after sender setup.
- **The confirm route.** `/confirm/<token>` flips `email_confirmed` 0 → 1 with a
  timestamp — proven both via the test client (302) and via a real emailed link
  clicked in a browser against the running dev server.
- **The sign-in gate.** `tests/test_signin_gate.py` — 4 passed on the laptop
  (Python 3.12, pytest 7.2.0) and in the sandbox with no `.env`/DB. Also manually
  confirmed against the dev DB by toggling `roger`'s flag (confirmed → in;
  unconfirmed → blocked with the confirm message).
- **`doctor.py` mail check.** All PASS on the laptop: three MAIL vars present, SMTP
  relay reachable over TCP.

### Not verified
- **DKIM/SPF domain authentication for `onemuseum.net`.** Delivery to one
  `rl.co.za` inbox succeeded, but it is NOT confirmed whether full DKIM/SPF DNS
  records are in place at GoDaddy, or whether delivery rode on sender-verification
  alone. Until `onemuseum.net` shows **authenticated** on Brevo's Domains tab,
  expect spam-foldering / rejection at scale (Gmail/Yahoo). **Action item.**
- **The gate against production.** Production is still suspended (503); the gate is
  proven on the laptop only.
- **The resend path for a blocked user.** `/resend_email_confirmation` is
  `@login_required`; a gated-out user cannot reach it. No public resend route exists
  yet (F-029).
- **Password-reset email.** Not exercised; known broken (B-010).

---

## 3. Findings from this session (for BACKLOG.md / DECISIONS.md)

1. **B-005 is now fixed** by the sign-in gate. Confirmation enforces access.
2. **`send_reset_email()` is broken (proposed B-010).** It constructs a fresh
   `mail = Mail()` — an unconfigured Flask-Mail instance — instead of using the
   app's configured `mail`. So the reset send fails/does nothing. The confirmation
   path works because `routes.py` imports the configured `mail`. Fix: use the shared
   configured instance.
3. **No resend route for blocked users (proposed F-029).** The gate blocks
   unconfirmed users from login, but the only resend route requires login. A public
   resend-by-email route (or equivalent) is needed before the gate is user-complete.
4. **Confirm-link base URL is environment-sensitive.** `generate_confirmation_email`
   builds the link from the request host (`_external=True`). In the shell this must
   be set explicitly; `https://onemuseum.net` → dead production (503),
   `http://127.0.0.1:5001` → dev. Recommend deriving it from config (`APP_BASE_URL`
   or `SERVER_NAME`+`PREFERRED_URL_SCHEME`) so dev and prod build correct links
   automatically.
5. **Brevo authorised-IP protection.** New accounts block SMTP relay from
   unrecognised IPs (`525 5.7.1 Unauthorized IP address`). Authorise the IP Brevo
   *logs*, not what `curl` reports (they differ if the connection switches). Stay on
   one connection per test session. Production/cloud needs a stable egress IP
   authorised. Do not disable IP blocking.
6. **Test suite is environment-coupled (housekeeping).** `conftest.py`'s `app`
   fixture calls `create_app()` with no test config, and `validate_config` hard-
   requires the `MYSQLCONN_*` vars — so the existing suite only runs where `.env`
   exists. `test_signin_gate.py` avoids this with its own `_TestConfig`; a shared
   test-config path would let the whole suite run in CI. Also: `test_favourites.py`
   is a stub (`assert True`).

### Proposed decision to log

- **D-009:** F-018 enforced at sign-in via an `email_confirmed` gate inside the
  password-success branch (absorbs B-005); the B-003/B-006 bypass is deliberately
  left for its own history-scrub increment. Send failures are logged (not raised)
  via `diaglog.log_error` at all three mail sites. `doctor.py` mail reachability is
  a TCP-only probe by design, to avoid Brevo auth/IP side effects.

---

## 4. Git — suggested commits

Code before docs, grouped by concern. Adjust paths as needed.

```
# 1. F-018 gate + send hardening
git add onemuseum/users/routes.py onemuseum/users/utils.py
git commit -m "F-018: gate sign-in on email_confirmed; log mail send failures

signin() now blocks login when email_confirmed is falsy (absorbs B-005), checked
inside the password-success branch above login_user; the B-003/B-006 bypass is
untouched. The three mail send sites (signup, resend, reset) wrap mail.send() in
try/except -> diaglog.log_error so a failure is logged, not lost on the thread."

# 2. Gate tests
git add tests/test_signin_gate.py
git commit -m "F-018: add self-sufficient sign-in gate tests

Four tests via a local _TestConfig + monkeypatched user lookup: unconfirmed
blocked, None-flag blocked, confirmed passes, wrong password never reaches the
gate. Run with no .env and no database."

# 3. doctor mail check
git add doctor.py
git commit -m "doctor: add outbound-mail check (config + TCP reachability)

Section 7 confirms MAIL_* are set (secret not printed) and TCP-connects to the
SMTP relay port without authenticating, so a broken mail setup is visible early
without tripping Brevo's authorised-IP protection."

# 4. Documentation + records
git add docs/TECHREF-email-handling.md updates/APPLY-v1.0.5-F018.md docs/BACKLOG.md updates/DECISIONS.md
git commit -m "docs: Email Handling chapter, F-018 APPLY, backlog/decisions

Adds the Technical Reference Email Handling chapter; records B-010 (broken
password-reset send), F-029 (public resend route), and D-009 (F-018 enforcement)."
```

(Include `updates/NOTE-F018-brevo-transport-proven.md` in commit 4 if kept.)

---

## 5. State at close

- **F-018:** transport proven, confirm route proven, sign-in gate enforced and
  tested. B-005 closed. User-complete pending F-029 (resend) and the DNS action.
- **Laptop dev DB:** `roger` confirmed; keep one account unconfirmed
  (e.g. `sholeen`) to retain the gate test pair.
- **Brevo:** sender `noreply@onemuseum.net` verified; domain authentication
  (DKIM/SPF) status to be confirmed on the Domains tab.
- **Production:** still offline (Plesk 503); gate not yet exercised there.
- **Code:** on disk, verified (`pytest` 4 passed; `doctor.py` all PASS),
  ready to commit (section 4).
- **Next:** DKIM/SPF at GoDaddy; F-029 resend route; B-010 reset-email fix; then
  the remaining launch-blocker arc (B-003/B-006 history scrub, F-016) before
  production re-launch.
