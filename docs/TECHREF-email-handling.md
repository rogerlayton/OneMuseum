# Technical Reference — Email Handling

**Status:** Draft, v1.0.5. Standalone chapter; slots into the Technical Reference Guide.
**Last verified:** 2026-07-29 (confirmation flow proven end to end to a real inbox).

This chapter covers OneMuseum's outbound email: the provider (Brevo), how mail is
configured and sent, the email-confirmation flow, how to test it in dev, and the
traps discovered while getting it working. Read the "Known traps" section before
touching anything — most of a day was spent rediscovering those.

---

## 1. Overview

OneMuseum sends two kinds of transactional email, both via **Brevo** (SMTP relay):

1. **Email confirmation** — sent on signup and on demand, to verify a user controls
   the address they registered. **Proven working end to end** (2026-07-29).
2. **Password reset** — sends a tokenised reset link. **Currently broken** — see
   §7 (known bug). Do not assume this path works.

Provider: **Brevo** (brevo.com), SMTP relay `smtp-relay.brevo.com:587`, STARTTLS.
Sending address: `noreply@onemuseum.net` (hardcoded in the message builders — see §3).

---

## 2. Configuration

### 2.1 Config keys (onemuseum/config.py)

| Key            | Source            | Notes                                              |
|----------------|-------------------|----------------------------------------------------|
| `MAIL_SERVER`  | `.env`            | `smtp-relay.brevo.com`                              |
| `MAIL_PORT`    | **hardcoded 587** | NOT read from `.env` — see note below              |
| `MAIL_USE_TLS` | **hardcoded True**| NOT read from `.env` — see note below              |
| `MAIL_USERNAME`| `.env`            | Brevo **SMTP login** (e.g. `xxxx@smtp-brevo.com`)  |
| `MAIL_PASSWORD`| `.env`            | Brevo **SMTP key** (distinct from the REST API key)|

**Note — port/TLS are hardcoded, not env-driven.** `MAIL_PORT = 587` and
`MAIL_USE_TLS = True` are fixed in `config.py`. Any `MAIL_PORT` / `MAIL_USE_TLS`
lines in `.env` are inert. This is fine for Brevo (587/STARTTLS is what we want),
but is a minor inconsistency; a future tidy could make them env-driven.

**Note — there is no `MAIL_DEFAULT_SENDER` in config.** The sender is set explicitly
on each `Message` (`sender='noreply@onemuseum.net'`), so a default sender is not
required. Consequence: to change the from-address you edit the message builders in
`users/utils.py` (§3), not config.

### 2.2 Brevo credentials

Both live in Norton Password Manager. The SMTP key is shown **once** at generation —
copy it immediately. It is a *separate* credential from the Brevo REST API key; the
SMTP relay needs the SMTP key.

---

## 3. How mail is built and sent

Two builders in `onemuseum/users/utils.py`:

- `generate_confirmation_email(user_email)` — returns a Flask-Mail `Message` with an
  HTML body rendered from `templates/email_confirmation.html`. The confirm link is
  built with `url_for('users.confirm_email', ..., _external=True)`.
- `send_reset_email(user)` — builds the password-reset message. **Broken** (§7).

The confirmation message is *sent* from the route (`users/routes.py`), not from the
builder. `signup()` and `resend_email_confirmation()` send it on a background thread:

```python
@copy_current_request_context
def send_email(message):
    with current_app.app_context():
        mail.send(message)
email_thread = Thread(target=send_email, args=[msg])
email_thread.start()
```

`mail` here is the app's configured Flask-Mail instance, imported from `..`. This is
why confirmation works and reset does not (§7 uses a fresh unconfigured `Mail()`).

**Send call sites (three):**
- `users/routes.py` — `send_email()` thread in `signup()`
- `users/routes.py` — `send_email()` thread in `resend_email_confirmation()`
- `users/utils.py` — `mail.send(msg)` in `send_reset_email()` (synchronous, broken)

None currently wrap the send in error handling — a failure dies silently on the
thread. Hardening these with `diaglog.log_error` is outstanding F-018 code work.

---

## 4. The email-confirmation flow

1. **Signup** (`/signup`) inserts the user with `email_confirmed = False` and sends
   the confirmation email on a thread. (Direct DB inserts / admin CLI-created users
   do NOT go through this path and are typically already `email_confirmed = 1`.)
2. **Email** contains a link: `<base>/confirm/<token>`. The token is an itsdangerous
   `URLSafeTimedSerializer` token, salt `email-confirmation-salt`, **30-minute** expiry
   (`max_age=1800`).
3. **Confirm** (`/confirm/<token>`) verifies the token; on success sets
   `email_confirmed = True` and `email_confirmed_on = now`, then redirects home.
   Expired/invalid → flash error, redirect to signin. Already-confirmed → info flash.
4. Confirmation is **permanent** — the confirm route only ever sets the flag true; it
   is never re-verified or expired.

**Important — `email_confirmed` does NOT yet gate sign-in.** As of this draft,
`signin()` logs a user in on a correct password regardless of `email_confirmed`.
Adding that gate is outstanding F-018 code work (absorbs B-005). Until then,
confirmation is recorded but enforces nothing.

---

## 5. The base-URL trap (dev vs prod)

The confirm link is built with `_external=True`, so it needs a host. The host comes
from the request context. **This is the single biggest dev gotcha.**

- In a **real HTTP request** (a user hitting `/signup`), Flask knows the host from the
  request — the link is correct automatically.
- In the **Flask shell** (used for test sends) there is no request, so `url_for`
  raises `RuntimeError: Unable to build URLs outside an active request without
  'SERVER_NAME'`. You must push a request context with an explicit `base_url`.

**The base_url you choose becomes the link in the email:**
- `base_url='https://onemuseum.net'` → link points at **production**. Production is
  currently **suspended (503)** pending the auth-blocker work, so this link dies.
- `base_url='http://127.0.0.1:5001'` → link points at your **dev app**. Use this for
  dev testing.

Future improvement (recommended): derive the confirm-link base from config
(`APP_BASE_URL`, or `SERVER_NAME` + `PREFERRED_URL_SCHEME`) so dev and prod each build
correct links without a hand-set `base_url`.

---

## 6. Testing recipes

### 6.1 Prove SMTP transport (does mail leave and get accepted by Brevo?)

In `python -m flask shell`:

```python
from onemuseum import mail
from onemuseum.users.utils import generate_confirmation_email
from flask import current_app
with current_app.test_request_context('/', base_url='http://127.0.0.1:5001'):
    msg = generate_confirmation_email("roger@rl.co.za")
    print("SENDER:", msg.sender, "| RECIPIENTS:", msg.recipients)
    mail.send(msg)
    print("SEND RETURNED OK")
```

`SEND RETURNED OK` means Brevo *accepted* the message — NOT that it was delivered.
Confirm delivery in **Brevo → Transactional → Statistics/Logs**: look for a
**Delivered** event, not just **Sent**. "Sent, 0 Delivered" = accepted by Brevo,
rejected by the recipient (usually domain-authentication — §8).

### 6.2 Test the confirm ROUTE without email or a browser (preferred dev test)

The Flask shell is NOT a web server, so an emailed link cannot be clicked against it.
To test the route logic, use the test client — no server, no browser, no SMTP:

```python
from itsdangerous import URLSafeTimedSerializer
from flask import current_app
s = URLSafeTimedSerializer(current_app.config['SECRET_KEY'])
token = s.dumps("roger@rl.co.za", salt='email-confirmation-salt')
resp = current_app.test_client().get(f'/confirm/{token}')
print(resp.status_code)   # 302 = success (redirect after confirming)
```

Then verify the DB flag flipped:

```
bash ./scripts/db.sh query "SELECT Email, email_confirmed, email_confirmed_on FROM Users WHERE Email='roger@rl.co.za';"
```

`email_confirmed = 1` with a timestamp = confirmed. This is the repeatable dev test.

### 6.3 Prove the real user journey (once)

To exercise the true email→click→confirm path:
1. Set the account unconfirmed:
   `bash ./scripts/db.sh query "UPDATE Users SET email_confirmed=0, email_confirmed_on=NULL WHERE Email='roger@rl.co.za';"`
2. Send with a **local** base_url (§6.1) so the link is `127.0.0.1:5001`.
3. **Start the dev server in a separate terminal** (`make run` / `python -m flask run
   --port 5001`) — the shell is not a server.
4. Click the emailed link **promptly** (30-min token). Any browser works once the
   server is up; `127.0.0.1` is not browser-specific.
5. Re-check the DB flag (§6.2).

To test the future sign-in gate you need one **confirmed** and one **unconfirmed**
account. Keep e.g. `roger` confirmed and `sholeen` unconfirmed (`email_confirmed=0`).

---

## 7. Known bug — password-reset email is broken

`send_reset_email()` in `users/utils.py` does `mail = Mail()` — creating a fresh,
**unconfigured** Flask-Mail instance instead of using the app's configured `mail`.
That local instance has no server/credentials, so `mail.send()` on the reset path
fails or silently does nothing. The confirmation path avoids this by importing the
configured `mail` from `..` in `routes.py`. **Fix:** use the shared configured `mail`
object (import it, don't construct a new one). Record as a backlog B-item.

---

## 8. Known traps (hard-won — read before changing anything)

- **Brevo authorised-IP blocking.** New Brevo accounts block SMTP relay from
  unrecognised IPs: `525 5.7.1 Unauthorized IP address`. Authorise the IP Brevo
  *logs* (dashboard → Security → Authorized IPs, click ✓ on the flagged row, or click
  the link in Brevo's "Verify a new IP" email) — NOT what `curl` reports; they differ
  if the connection is switched mid-test. **Stay on ONE connection per test session.**
  Do not disable IP blocking as a shortcut — it leaves the SMTP key as the only
  control against relay abuse as `noreply@onemuseum.net`.
- **Egress IP changes.** A laptop's public IP changes with connection (fibre / mobile
  / etc.), each change → a fresh `525`. Production/cloud (Docker/K8s/AWS/Azure) often
  egresses from a shared NAT IP that differs from the server's public IP — authorise
  the deployment's *stable egress IP* there.
- **`SEND RETURNED OK` is not delivery.** It only means Brevo accepted the message.
  Always confirm **Delivered** in Brevo's logs.
- **Domain authentication (DKIM/SPF) — VERIFY STATUS, do not assume.** Delivery was
  proven to a `rl.co.za` inbox, but it is NOT confirmed whether full DKIM/SPF DNS
  records are in place at GoDaddy, or whether delivery succeeded on Brevo
  sender-verification alone. Until `onemuseum.net` shows **authenticated** (green) on
  Brevo's Domains tab, expect spam-foldering or rejection at scale (Gmail/Yahoo). For
  unauthenticated domains Brevo may rewrite the from-address to `@brevosend.com`.
  **Action:** authenticate `onemuseum.net` on Brevo Domains, add the generated DKIM
  and SPF records at GoDaddy, and re-test for a Delivered event.
- **The Flask shell is not a web server.** It sends mail fine (has app context) but
  serves no HTTP — `/confirm` links give `ERR_CONNECTION_REFUSED` against it. Run the
  dev server separately to click links.
- **Port 5000 vs 5001.** macOS AirPlay Receiver owns port 5000 on every reboot; the
  project default is 5001. Server and confirm-link port must both be 5001.
- **`scripts/db.sh` grammar.** Use `bash scripts/db.sh query "SELECT ..."` — the
  script has its own subcommands (`query`, `shell`, `file`, `backup`, `dump`); it is
  NOT a passthrough to `mysql`, so `-e` does not work. If you get "permission denied",
  the executable bit was stripped — `chmod +x scripts/db.sh` (and optionally
  `git update-index --chmod=+x scripts/db.sh` so it survives future archives).

---

## 9. Outstanding work (F-018 and related)

- **Code — sign-in gate:** block login when `email_confirmed` is false (absorbs B-005).
- **Code — send hardening:** wrap the three send sites (§3) with `diaglog.log_error`
  so failures are logged, not lost on the thread.
- **Code — resend gap:** `/resend_email_confirmation` is `@login_required`, but the
  gate blocks unconfirmed users from logging in — so they cannot reach resend. Needs a
  public resend-by-email route (or equivalent) before the gate is user-complete.
- **Bug — password reset:** fix `send_reset_email()` (§7).
- **DNS — domain authentication:** DKIM/SPF for `onemuseum.net` at GoDaddy (§8).
- **Config — base URL:** derive confirm-link base from config, not a hand-set
  `base_url` (§5).
- **Registration hardening (F-016):** rate limiting / CAPTCHA before `/signup` reopens.
