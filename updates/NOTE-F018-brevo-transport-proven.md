# NOTE — F-018 Email Confirmation: Brevo SMTP transport proven

**Date:** 2026-07-29
**Increment:** v1.0.5 (in progress)
**Status:** Transport PROVEN. Blocker is DNS (DKIM/SPF for onemuseum.net). Code items outstanding.
**Not an APPLY** — no code changed this session; this records a working-state milestone and the exact next steps.

---

## What was proven today

The Brevo SMTP transport works end to end from the app. Using `python -m flask shell`
with a pushed request context (needed so `url_for(..., _external=True)` can build the
confirm link), a real confirmation message was handed to Brevo successfully:

- `mail.send(generate_confirmation_email(...))` returned cleanly (no exception).
- Sender resolved as `noreply@onemuseum.net`; recipient as the test address.
- Brevo dashboard shows the real email — subject "OneMuseum - Confirm Your Email" —
  as **Sent**.

The template, sender, credentials, relay host, port and TLS are all correct.

## The remaining blocker: domain authentication (DNS)

Brevo shows **1 Sent, 0 Delivered**. "Sent" = Brevo accepted and attempted relay;
it does **not** mean the recipient accepted it. There is no Delivered event, and a
paired **Error** event is present.

Cause (high confidence): `onemuseum.net` is not yet domain-authenticated in DNS.
With no DKIM and no SPF authorising Brevo to send as `onemuseum.net`, receiving
servers treat `noreply@onemuseum.net` relayed via Brevo as unauthenticated and
reject/quarantine it. Accepted by Brevo (Sent), refused by the recipient (no Delivered).

**This is the DNS piece — the Munirih session.** Email transport and DNS were always
paired for exactly this reason.

### DNS next steps (turnkey for the Munirih session)
1. Brevo → **Senders, Domains & Dedicated IPs → Domains → Authenticate `onemuseum.net`**.
   This generates the exact DKIM (TXT) and SPF `include` records (and a DMARC suggestion).
2. Add those records at **GoDaddy** (DNS host for onemuseum.net).
3. Re-run the shell send test. Success looks like a **Delivered** event in Brevo and the
   mail arriving in the inbox (not spam).

---

## Authorized-IP caveat (recorded so it doesn't surprise us again)

Brevo blocks SMTP relay from unrecognised IPs (`525 5.7.1 Unauthorized IP address`),
on by default for new accounts. This session hit it repeatedly because the laptop's
egress IP kept changing (fixed line → Vodacom mobile `105.245.60.48` → Fibre) as the
connection was switched.

- **Fix each time:** authorise the IP Brevo actually logs (dashboard → Security →
  Authorized IPs, click the ✓ on the flagged row; or click the link in Brevo's
  "Verify a new IP" email). Authorise the IP Brevo *logged*, not what `curl` reported —
  they differed here because the connection was switched mid-test.
- **Testing hygiene:** stay on ONE connection (Fibre) for a whole test session.
- **Production/cloud (Munirih):** authorise the *stable egress IP* of the deployed
  environment. Brevo's own docs warn that Docker/K8s/AWS/Azure egress often differs
  from the server's public IP (shared NAT). Do NOT disable IP blocking as a shortcut —
  that leaves the SMTP key as the only control against relay abuse as `noreply@onemuseum.net`.

---

## Code still owed for F-018 (small, well-scoped — NOT done today)

1. **`email_confirmed` gate in `signin()`** (absorbs B-005). After the password check
   passes, if `user.email_confirmed` is false: block login, flash a message with a
   resend link, do not call `login_user`. Currently `signin()` has no such check, so
   confirmation gates nothing.

2. **Harden the send call sites with diaglog logging.** Three sites currently send with
   no error capture — a failure (like today's `525`) dies silently:
   - `onemuseum/users/routes.py:45` — `send_email()` thread in `signup()`
   - `onemuseum/users/routes.py:174` — `send_email()` thread in `resend_email_confirmation()`
   - `onemuseum/users/utils.py:38` — `mail.send(msg)` in `send_reset_email()` (synchronous)
   Wrap each in try/except and call `diaglog.log_error(where, message)` (errors are always
   logged regardless of `DIAG_LOGGING`). This is the one genuine F-015 ↔ F-018 connection.

## Scope guard (unchanged rulings)

- **B-003 / B-006** (hardcoded FORCED SIGN IN bypass in `signin()` / `signin_reauth()`)
  stays a SEPARATE history-scrub increment. Do not fold into F-018. When adding the
  gate above, leave the bypass block untouched for its own increment.
- Confirmation is permanent / never re-verified — already how `confirm_email()` behaves
  (only ever sets the flag true). No change needed there.
