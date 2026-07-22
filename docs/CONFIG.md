# Configuration Reference

Single source of truth for OneMuseum configuration. Kept **in step with
`onemuseum/config.py`** by an automated drift-check: `tests/test_config_docs.py`
fails if this table and the code disagree. If you change one, change the other
in the same commit.

Configuration is supplied via **environment variables** (read in
`onemuseum/config.py`). In development these are typically provided via a local
`.env` (not committed) or the shell; in production via the process manager /
container environment.

---

## Environment variables

| Variable | Purpose |
| --- | --- |
| `SECRET_KEY` | Flask session signing / CSRF. Must be set; keep secret. |
| `MAIL_SERVER` | SMTP host for Flask-Mail (password reset, confirmations). |
| `MAIL_USERNAME` | SMTP username. |
| `MAIL_PASSWORD` | SMTP password. |
| `MYSQLCONN_HOST` | MariaDB/MySQL host. |
| `MYSQLCONN_PORT` | MariaDB/MySQL port. |
| `MYSQLCONN_USER` | MariaDB/MySQL user. |
| `MYSQLCONN_PASSWORD` | MariaDB/MySQL password. |
| `MYSQLCONN_DATABASE` | MariaDB/MySQL database name. |

> The `MYSQLCONN_*` names are retained as-is in v1.0.0 (behaviour-preserving).
> They will be revisited if/when the Postgres migration (F-001) lands.

## Fixed (non-environment) config values

Set directly in `onemuseum/config.py`, not from the environment:

- `MAIL_PORT = 587`
- `MAIL_USE_TLS = True`
- `BASE_DIR` — absolute path of the package directory (derived at import).

---

## Entrypoint & run

- WSGI entrypoint: `wsgi.py` at the project root (`app = create_app()`).
- Production: `gunicorn wsgi:app`
- Development: `flask --app wsgi run` (or `python wsgi.py`).
