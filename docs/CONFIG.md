# Configuration Reference

Single source of truth for OneMuseum configuration. Kept **in step with
`onemuseum/config.py`** by an automated drift-check: `tests/test_config_docs.py`
fails if this table and the code disagree. If you change one, change the other
in the same commit.

Configuration is supplied via **environment variables** (read in
`onemuseum/config.py`). A local **`.env`** at the project root is loaded
automatically at import time (F-011), so configuration is identical however the
app is launched — `flask run`, `gunicorn`, or the VS Code debugger. Real
environment variables take precedence over `.env`.

`.env` is gitignored and must never be committed. **`.env.example`** is
committed with placeholders so the required set is discoverable from the repo:

```
cp .env.example .env
```

### Required vs optional

The six settings marked **required** below must be present or the app
**refuses to start** (F-012). Validation runs in `create_app()` and raises a
`ConfigError` naming *every* missing variable at once, rather than failing
identically on every subsequent request. Mail settings are optional: the app
runs without them and only mail features are unavailable.

---

## Environment variables

| Variable | Purpose |
| --- | --- |
| `SECRET_KEY` | **Required.** Flask session signing / CSRF. Keep secret. |
| `MAIL_SERVER` | SMTP host for Flask-Mail (password reset, confirmations). |
| `MAIL_USERNAME` | SMTP username. |
| `MAIL_PASSWORD` | SMTP password. |
| `MYSQLCONN_HOST` | **Required.** MariaDB/MySQL host. |
| `MYSQLCONN_PORT` | **Required.** MariaDB/MySQL port. |
| `MYSQLCONN_USER` | **Required.** MariaDB/MySQL user. |
| `MYSQLCONN_PASSWORD` | **Required.** MariaDB/MySQL password. |
| `MYSQLCONN_DATABASE` | **Required.** MariaDB/MySQL database name. |

> The `MYSQLCONN_*` names are retained as-is in v1.0.0 (behaviour-preserving).
> They will be revisited if/when the Postgres migration (F-001) lands.

## Fixed (non-environment) config values

Set directly in `onemuseum/config.py`, not from the environment:

- `MAIL_PORT = 587`
- `MAIL_USE_TLS = True`
- `BASE_DIR` — absolute path of the package directory (derived at import).

---

## Diagnostics

Before launching the app — or whenever it will not start — run the standalone
diagnostic from the project root:

```
python doctor.py
```

It imports nothing from the `onemuseum` package, so it still works when the app
itself cannot start. It reports, independently so one failure does not mask the
rest: whether `.env` was found; which required variables are set or missing
(secrets are never printed, only their length); whether the database driver
imports; whether MariaDB is reachable and the credentials authenticate; whether
the database and its four stored procedures (`ChenhallDetails`,
`GenCategories`, `GenDetails`, `UserEntityFavourite`) exist; and whether a
`SELECT` actually succeeds. Exit code is 0 if everything passed, 1 otherwise.

---

## Entrypoint & run

- WSGI entrypoint: `wsgi.py` at the project root (`app = create_app()`).
- Production: `gunicorn wsgi:app`
- Development: `flask --app wsgi run` (or `python wsgi.py`).
