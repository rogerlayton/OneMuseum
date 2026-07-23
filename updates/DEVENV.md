# Development Environment (cold start)

How to get OneMuseum running on a developer machine from nothing. Written for
a second developer joining the project; also the recovery procedure if your own
setup stops working.

`docs/CONFIG.md` is the *reference* for what each setting means. This file is
the *procedure*.

> **Secrets.** Every credential below is a **placeholder**. Real values are
> never written into this file, the repository, or any shared document — they
> are passed directly by Roger. Development credentials are throwaway and must
> differ from production.

> **Returning to the project after a break?** The domain model, schema and
> stored procedures are unchanged. The plumbing around them is not. If you last
> worked on this when it was a single `app.py` talking to a locally-installed
> MySQL, see [What changed](#what-changed) at the end before starting.

---

## 0. Prerequisites

- **Docker Desktop** (for MariaDB).
- **Python 3.12**.
- **Node.js and the KaTeX CLI** — `npm install -g katex`. See the note below.
- **git**, and access to `github.com/rogerlayton/OneMuseum`.
- The **database dump** — a `.zip` containing one `.sql` file, produced by
  SQLBackupAndFTP. Obtain from Roger directly; it is **not** in the repository.
  It contains schema, data **and** stored procedures.

Platform note: these instructions are written for macOS. On Windows or Linux
the Docker commands are the same; only paths differ. **Do not** run the
project from inside a cloud-synced folder.

Windows specifics are collected in [Platform notes](#platform-notes) below.

> **Why KaTeX is a prerequisite (B-004).** Lesson content containing maths is
> rendered by `markdown_katex`, which shells out to a `katex` binary. The
> binaries bundled with that package are **x86_64 only** — `x86_64-Darwin`,
> `x86_64-Linux`, `x86_64-Windows` — with no arm64 build. On Apple Silicon this
> raises `NotImplementedError` and any page containing maths returns a 500,
> while every other page renders normally. A native `katex` on PATH takes
> precedence over the bundled binary and fixes it. On x64 Windows the bundled
> binary works, so the failure will not appear there — install Node anyway, so
> that environments match and so the dependency is not forgotten when the
> application is containerised. `python doctor.py` checks this (section 7).

---

## 1. Clone

```
git clone https://github.com/rogerlayton/OneMuseum.git
cd OneMuseum
```

Authentication: GitHub no longer accepts account passwords for git operations.
Use the GitHub CLI (`gh auth login` -> GitHub.com -> HTTPS -> Yes -> login with
a web browser), which also configures git's credential helper. A Personal
Access Token works too.

---

## 2. MariaDB container

**The `--lower-case-table-names=1` flag is essential and can only be set when
the container is first created.** The dump originates from a Windows MariaDB
where table names are case-insensitive; on Linux (inside the container) they
are case-sensitive by default. Without the flag the dump loads and then fails
mysteriously at query time. If you get this wrong, the container must be
destroyed and recreated — the setting is baked into the initialised data
directory.

Since v1.0.3 the container is defined declaratively in `docker-compose.yml` at
the project root, which carries the flag and the pinned image version:

```
docker compose up -d
docker compose ps
```

Set `MARIADB_ROOT_PASSWORD` in `.env` first (section 5) — Compose reads it from
there.

The equivalent manual command, for reference or recovery:

```
docker run -d \
  --name onemuseum-mariadb \
  -e MARIADB_ROOT_PASSWORD='<dev-root-password>' \
  -e MARIADB_DATABASE='onemuseum2' \
  -p 3306:3306 \
  -v onemuseum-mariadb-data:/var/lib/mysql \
  mariadb:10.6 \
  --lower-case-table-names=1
```

Reference configuration (Roger's machine, recovered 2026-07-23):

| Setting | Value |
| --- | --- |
| Image | `mariadb:10.6` |
| Container name | `onemuseum-mariadb` |
| Volume | `onemuseum-mariadb-data` -> `/var/lib/mysql` |
| Port | `3306` -> `3306` |
| Database | `onemuseum2` |
| Startup flag | `--lower-case-table-names=1` |

> Note the database is **`onemuseum2`**, not `onemuseum`.

The named volume makes the data survive container restarts. The container is
disposable; the volume is not. `docker compose down` stops the container and
preserves the data.

> **Never run `docker compose down -v`.** The `-v` flag deletes the volume and
> the entire database with it.

> **The root password cannot be changed by environment variable after first
> run.** Because the volume persists, `MARIADB_ROOT_PASSWORD` is **ignored** on
> any container created against an already-initialised volume. Use `ALTER USER`
> inside the running container instead.

Check it is running:

```
docker ps
```

---

## 3. Load the dump

Unzip the dump, then load it (from the directory containing the `.sql`):

```
docker exec -i onemuseum-mariadb \
  mysql -u root -p'<dev-root-password>' onemuseum2 < <dumpfile>.sql
```

This takes a few minutes. Then **verify the stored procedures arrived** — the
application calls four of them, and if the dump's routines failed to create,
the schema and data will look fine while every details page 500s:

```
docker exec -it onemuseum-mariadb \
  mysql -u root -p'<dev-root-password>' \
  -e "SHOW PROCEDURE STATUS WHERE Db = 'onemuseum2';"
```

Confirm these four are listed: **`GenDetails`**, **`ChenhallDetails`**,
**`GenCategories`**, **`UserEntityFavourite`**. (Many other procedures will
also appear — `slugify_*` helpers and `UPLOAD_*` routines belonging to the
separate OneMuseumIngestor application. That is expected.)

`python doctor.py` (section 6) checks all four automatically.

When taking your own backup, include `--routines` or the stored procedures are
lost:

```
docker exec onemuseum-mariadb \
  mysqldump -u root -p'<dev-root-password>' --routines onemuseum2 > backup.sql
```

---

## 4. Python environment

macOS / Linux:

```
python3.12 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
pip install -r requirements-dev.txt
```

Windows (PowerShell):

```powershell
py -3.12 -m venv .venv
.venv\Scripts\Activate.ps1
pip install -r requirements.txt
pip install -r requirements-dev.txt
```

> If PowerShell blocks the activate script, run
> `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned` once.

---

## 5. Configuration

> This step was the subject of **D-006** and is resolved as of **v1.0.3**. The
> historical `env.sh` procedure is no longer used — see
> [What changed](#what-changed).

Configuration is read from a **`.env` file at the project root** (alongside
`wsgi.py`), loaded by `load_dotenv()` in `onemuseum/config.py` at import time.
It therefore applies identically however the app is launched — `flask run`,
`gunicorn`, or the VS Code debugger — and does not depend on the shell.

```
cp .env.example .env
```

Then edit `.env`:

```
SECRET_KEY='<any-long-random-string>'
MYSQLCONN_HOST='127.0.0.1'
MYSQLCONN_PORT='3306'
MYSQLCONN_USER='<db-user>'
MYSQLCONN_PASSWORD='<db-password>'
MYSQLCONN_DATABASE='onemuseum2'
MARIADB_ROOT_PASSWORD='<dev-root-password>'
MAIL_SERVER='<smtp-host>'
MAIL_USERNAME='<smtp-user>'
MAIL_PASSWORD='<smtp-password>'
```

`MYSQLCONN_HOST` is `127.0.0.1` because the container publishes port 3306 onto
the host. (This changes if the *application* is later containerised — F-002;
see the known limitation in section 9.) `MARIADB_ROOT_PASSWORD` is read by
`docker-compose.yml`. `MAIL_*` is only needed for signup and password-reset
flows; the application runs without it.

Generate a development `SECRET_KEY`:

```
python -c "import secrets; print(secrets.token_hex(32))"
```

Pick one and keep reusing it — changing it invalidates existing session
cookies and signs you out.

`.env` is gitignored and must never be committed. `.env.example` is committed
with placeholders only.

> **Paste carefully.** `.env` must contain only `KEY=value` lines and comments.
> If shell commands or stray text get into it, `python-dotenv` reports
> "could not parse statement starting at line N" and the affected variables
> silently come through **unset**. An empty value (`KEY=` with nothing after)
> also counts as unset.

### Missing configuration now fails at startup

As of **F-012**, if a required setting is missing the application **refuses to
start** and names every missing variable at once, with the path it expected
`.env` at and the command to fix it.

This replaces the previous behaviour, in which an unset `SECRET_KEY` let the
app start and then return 500 on *every* request — pages, CSS, JS, fonts and
images alike — with `RuntimeError: The session is unavailable because no secret
key was set`. The site appeared as an unstyled error page because the
stylesheets were failing too, and roughly forty identical tracebacks named
nothing useful.

---

## 6. Verify with the diagnostic

From the project root:

```
python doctor.py
```

`doctor.py` imports nothing from the `onemuseum` package, so it still works
when the application itself cannot start. It reports seven sections
independently, so one failure does not mask the rest:

| Section | Checks |
| --- | --- |
| 1 | `.env` found and loaded |
| 2 | Every required variable set (secrets shown as a length, never a value) |
| 3 | Database driver importable |
| 4 | MariaDB reachable, credentials valid, database exists |
| 5 | All four stored procedures present |
| 6 | `SELECT` succeeds on `users`, `museums`, `items`, `chenhallnomenclature` |
| 7 | KaTeX resolves a binary *and* renders a sample expression |

Exit code is 0 if everything passed, 1 otherwise.

**`doctor.py` must sit at the project root**, alongside `wsgi.py` — not inside
`onemuseum/`. It refuses to run from the wrong directory rather than
misreporting. Run it first whenever something will not start.

---

## 7. Run

```
flask --app wsgi run          # development, http://127.0.0.1:5000
gunicorn wsgi:app             # production-style
```

---

## 8. Debugging

`.vscode/launch.json` provides three configurations (Run and Debug panel, or
F5):

| Configuration | Use |
| --- | --- |
| **OneMuseum: Flask (debug)** | Run the app with breakpoints active |
| **OneMuseum: doctor.py** | Step through the diagnostic |
| **OneMuseum: pytest (current file)** | Debug the open test file |

The Flask configuration deliberately passes `--no-reload` and `--no-debugger`:

- **`--no-reload`** — the auto-reloader runs your code in a child process, and
  breakpoints set in the parent never bind. Debugging silently does nothing
  without this. The cost is that you must restart manually after code changes.
- **`--no-debugger`** — Werkzeug's built-in debugger would catch exceptions
  before VS Code sees them, so you would get the browser error page instead of
  breaking at the fault.
- **`justMyCode: false`** — lets you step into Flask, `mysql.connector` and
  other library code, not just OneMuseum's own.

Requires the VS Code Python extension (for `debugpy`). If F5 does nothing, that
is the first thing to check.

### VS Code and `.env`

VS Code may prompt that terminal environment injection is disabled and offer to
enable `python.terminal.useEnvFile`. **Leave it disabled.** `.env` is loaded in
code by `load_dotenv()`. Enabling terminal injection adds a second, competing
loading mechanism — and a stale terminal disagreeing with an edited `.env` is
exactly the class of failure D-006 exists to eliminate. `.vscode/settings.json`
sets it to `false` explicitly.

---

## 9. Building the application image

```
docker build -t onemuseum:dev .
docker run --rm -p 5000:5000 --env-file .env onemuseum:dev
```

The image installs Node and the KaTeX CLI, runs as an unprivileged user, and
takes all configuration from the environment — no secrets are baked in, and
`.env` is excluded by `.dockerignore`.

> **Known limitation.** A container cannot reach the database at `127.0.0.1` —
> that is the container's own loopback, not the host's. Running the image needs
> `host.docker.internal` (Docker Desktop) or both containers on a shared
> Compose network. Unresolved; part of F-002.

---

## 10. Verification — you are done when

- [ ] `docker ps` shows `onemuseum-mariadb` running.
- [ ] `python doctor.py` reports **all checks passed** (all seven sections).
- [ ] The app starts without a traceback.
- [ ] These four page types render:
  - [ ] home / a menu page
  - [ ] a browser list page (`/b/<entity>`)
  - [ ] a details page (`/d/...`)
  - [ ] a categories page (`/c/...`)
- [ ] A maths lesson (e.g. Equations) renders its equations.

---

## Known issues you will hit

Pre-existing; **not** caused by your setup.

- **Images do not display.** Root-caused in v1.0.3, not fixed. Two independent
  causes: (1) `onemuseum/images/routes.py` resolves its folder with
  `os.path.realpath('./static/images')`, which is relative to the *current
  working directory*, not the package — run from the project root it looks for
  `<root>/static/images`, which does not exist, and then falls back silently to
  `_missing_.jpg`, so there is no error to observe; (2) the image files are not
  in the repository at all — `onemuseum/static/images/` contains only
  `_missing_.jpg`. Fixing the path alone will not make images appear. Where the
  files should live (repository, mounted volume, or object storage) is an open
  design question — the schema has `digitalobjects` / `digitalrepositories`
  tables.
- **`tests/test_spec_sdf.py::test_menus` fails** (**B-002**) — pre-existing and
  test-only.
- **The page footer shows an old version string** — cosmetic, hardcoded.
- **A hardcoded sign-in bypass exists** in `onemuseum/users/routes.py`
  (**B-003**). You should know it is there. It is scheduled for removal in the
  user-access-control increment (D-007) and **must** be gone before public
  launch. Do not rely on it.
- **Thin dataset.** The development database has 100 users and 37 museums but
  only 1 item, so anything depending on item content will look broken when it
  is not.

**Resolved in v1.0.3:** *Equations/maths lessons return 500* (**B-004**) — this
was the missing native `katex` binary on arm64. See prerequisites.

---

## Platform notes

### Windows

- **Line endings.** Git on Windows may check files out with CRLF. A CRLF `.env`
  can yield values with a trailing `\r`, which shows up as an authentication
  failure against a password that looks correct. If you hit this, ensure `.env`
  is saved with LF endings (VS Code: click the `CRLF` indicator in the status
  bar and switch to `LF`).
- **Architecture.** Most Windows laptops are x64; Apple Silicon Macs are arm64.
  The same MariaDB image tag pulls a different build on each, and the bundled
  KaTeX binaries exist only for x86_64. This is why "it works on the other
  machine" is not proof it works here — run `python doctor.py`.
- `127.0.0.1` is correct for `MYSQLCONN_HOST`; the published port is reachable
  from the Windows host normally. `host.docker.internal` is not needed for
  local development.
- Docker Desktop should use the WSL 2 backend (the default).

---

## What changed

For a developer returning after a long break.

| Then | Now |
| --- | --- |
| Single `app.py` | Package `onemuseum/` with an application factory, `create_app()` |
| Routes in one file | Blueprints per area (`entities`, `users`, `admin`, `categories`, `images`, `main`, `support`, `pocs`, `errors`) |
| `python app.py` | `flask --app wsgi run`, entrypoint `wsgi.py` |
| Flask 2.2.2 | Flask 3.1.3 (see D-003 — 2.2.2 could not run under Werkzeug 3.x) |
| Locally-installed MySQL | MariaDB in Docker, data in a named volume |
| Credentials `export`ed in the shell via `env.sh` | `.env` at the project root, loaded in code (D-006, F-011) |
| Missing config surfaced as 500s on every request | Startup refuses and names what is missing (F-012) |
| No way to check the environment | `python doctor.py` |

The database content and structure are unchanged. Nothing above requires
re-learning the application itself; rationale for each change is in
`docs/DECISIONS.md`.

---

## Reference: recovering a lost configuration

If the settings are lost again, the running container knows most of them:

```
docker inspect onemuseum-mariadb --format '{{range .Config.Env}}{{println .}}{{end}}'
docker inspect onemuseum-mariadb --format '{{json .Config.Cmd}}'
docker inspect onemuseum-mariadb --format '{{json .Mounts}}'
docker port onemuseum-mariadb
```

These give the database name, root password, startup flags, volume and port
mapping respectively. This is exactly how the reference table in section 2 was
reconstructed — and precisely the archaeology that D-006 exists to make
unnecessary. Since v1.0.3, `.env` and `docker-compose.yml` hold this
information in the repository, and `python doctor.py` reports on it directly.
