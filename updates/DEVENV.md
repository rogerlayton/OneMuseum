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

---

## 0. Prerequisites

- **Docker Desktop** (for MariaDB).
- **Python 3.12**.
- **git**, and access to `github.com/rogerlayton/OneMuseum`.
- The **database dump** — a `.zip` containing one `.sql` file, produced by
  SQLBackupAndFTP. Obtain from Roger directly; it is **not** in the repository.
  It contains schema, data **and** stored procedures.

Platform note: these instructions are written for macOS. On Windows or Linux
the Docker commands are the same; only paths differ. **Do not** run the
project from inside a cloud-synced folder.

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

```
docker run -d \
  --name onemuseum-mariadb \
  -e MARIADB_ROOT_PASSWORD='<dev-root-password>' \
  -e MARIADB_DATABASE='onemuseum2' \
  -p 3306:3306 \
  -v onemuseum-data:/var/lib/mysql \
  mariadb:10.6 \
  --lower-case-table-names=1
```

Reference configuration (Roger's machine, recovered 2026-07-23):

| Setting | Value |
| --- | --- |
| Image | `mariadb:10.6` |
| Container name | `onemuseum-mariadb` |
| Port | `3306` -> `3306` |
| Database | `onemuseum2` |
| Startup flag | `--lower-case-table-names=1` |

> Note the database is **`onemuseum2`**, not `onemuseum`.

The named volume (`-v onemuseum-data:/var/lib/mysql`) makes the data survive
container restarts. Without it, everything is lost when the container is
removed.

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

---

## 4. Python environment

```
python3.12 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
pip install -r requirements-dev.txt
```

---

## 5. Configuration

> **This is the step that most often goes wrong**, and it is the subject of
> **D-006 / v1.0.3**. Read the current-state note at the end of this section.

The application needs these environment variables (full reference in
`docs/CONFIG.md`):

```
SECRET_KEY='<any-long-random-string>'
MYSQLCONN_HOST='127.0.0.1'
MYSQLCONN_PORT='3306'
MYSQLCONN_USER='<db-user>'
MYSQLCONN_PASSWORD='<db-password>'
MYSQLCONN_DATABASE='onemuseum2'
MAIL_SERVER='<smtp-host>'
MAIL_USERNAME='<smtp-user>'
MAIL_PASSWORD='<smtp-password>'
```

`MYSQLCONN_HOST` is `127.0.0.1` because the container publishes port 3306 onto
the host. (This changes if the *application* is later containerised — F-002.)
`MAIL_*` is only needed for signup and password-reset flows.

Generate a development `SECRET_KEY`:

```
python -c "import secrets; print(secrets.token_hex(32))"
```

Pick one and keep reusing it — changing it invalidates existing session
cookies and signs you out.

### Current state (before v1.0.3)

**The application does not read a `.env` file.** `load_dotenv` is not wired,
so a `.env` file on disk has no effect. Until F-011 lands, use a **gitignored
`env.sh`** in the repository root:

```
cat > env.sh << 'EOF'
export SECRET_KEY='<any-long-random-string>'
export MYSQLCONN_HOST='127.0.0.1'
export MYSQLCONN_PORT='3306'
export MYSQLCONN_USER='<db-user>'
export MYSQLCONN_PASSWORD='<db-password>'
export MYSQLCONN_DATABASE='onemuseum2'
EOF
echo "env.sh" >> .gitignore
```

Then, **in every new terminal**, before launching:

```
source env.sh
```

Environment variables set with `export` live only in the shell process that set
them. Close the terminal — or open a different tab — and they are gone. This
caused a full morning's confusion on 2026-07-23: the app had "worked yesterday"
with no code change, because the previous session's exports had simply died
with its terminal.

Verify before launching:

```
echo "KEY=$SECRET_KEY DB=$MYSQLCONN_DATABASE"
```

Both must be non-empty. **If `SECRET_KEY` is unset the app still starts**, then
returns 500 on *every* request — pages, CSS, JS, fonts and images alike —
with `RuntimeError: The session is unavailable because no secret key was set`.
The site appears as an unstyled error page because the stylesheets are failing
too. Fixing this (fail fast at startup, naming what is missing) is **F-012**.

---

## 6. Run

```
flask --app wsgi run          # development, http://127.0.0.1:5000
gunicorn wsgi:app             # production-style
```

---

## 7. Verification — you are done when

- [ ] `docker ps` shows `onemuseum-mariadb` running.
- [ ] The four stored procedures are listed (step 3).
- [ ] `echo $SECRET_KEY` is non-empty in the shell you will launch from.
- [ ] The app starts without a traceback.
- [ ] These four page types render:
  - [ ] home / a menu page
  - [ ] a browser list page (`/b/<entity>`)
  - [ ] a details page (`/d/...`)
  - [ ] a categories page (`/c/...`)

---

## Known issues you will hit

- **Images do not display.** Under investigation; where image files are meant
  to be stored is an open design question (the schema has `digitalobjects` /
  `digitalrepositories` tables). Not caused by your setup.
- **Equations/maths lessons return 500** (**B-004**). `markdown-katex` requires
  a native `katex` binary that is absent on macOS. Plain lessons are fine.
- **`tests/test_spec_sdf.py::test_menus` fails** (**B-002**) — pre-existing and
  test-only.
- **The page footer shows an old version string** — cosmetic, hardcoded.
- **A hardcoded sign-in bypass exists** in `onemuseum/users/routes.py`
  (**B-003**). You should know it is there. It is scheduled for removal in the
  user-access-control increment (D-007) and **must** be gone before public
  launch. Do not rely on it.

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
unnecessary.
