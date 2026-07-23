# APPLY — v1.0.3 (configuration & diagnostics)

Consolidated record of the v1.0.3 increment: what changed, what was verified,
what was not, and the git commands to commit it as the next HEAD.

**Scope delivered:** F-011 (`.env` loading), F-012 (fail-fast config
validation), plus a standalone diagnostic, developer environment
documentation, a Compose file, VS Code debug configuration, and a rebuilt
application image. Two defects were root-caused; one was fixed.

**Deferred to the next session:** F-013 (DB connection error handling), F-015
(diagnostic logging), F-014 (least-privilege DB user).

---

## 1. Files changed

### New

| File | Purpose |
| --- | --- |
| `doctor.py` | Standalone 7-section environment diagnostic. **Project root**, alongside `wsgi.py` — it deliberately imports nothing from the `onemuseum` package so it still works when the app cannot start. |
| `.env.example` | Committed template with placeholders only. The file a new developer copies. |
| `docker-compose.yml` | Declarative replacement for the manual `docker run`. |
| `.vscode/launch.json` | Three debug configurations (Flask, doctor, pytest). |
| `.vscode/settings.json` | Workspace settings, including the `useEnvFile` decision. |

### Modified

| File | Change |
| --- | --- |
| `onemuseum/config.py` | F-011: `load_dotenv()` at import; the four hardcoded DB literals restored to `os.environ.get`. F-012: adds `REQUIRED_CONFIG`, `ConfigError`, `validate_config()`. |
| `onemuseum/__init__.py` | Calls `validate_config(app.config)` immediately after `from_object`, before any extension initialises. |
| `docs/CONFIG.md` | Documents required vs optional, the `.env` mechanism, and the diagnostic. Kept in step with `config.py` per `tests/test_config_docs.py`. |
| `Dockerfile` | Rewritten — see section 4. |
| `updates/DEVENV.md` | **Merged**, not replaced. The existing cold-start procedure was retained as the base — it carried facts not otherwise recorded, notably the essential `--lower-case-table-names=1` flag and the `mariadb:10.6` pin — with v1.0.3 findings folded in. |
| `.dockerignore` | Added exclusions for `.venv`, `SQL`, `docs`, `tests`, and other host artefacts. The pre-existing `**/.env` exclusion was retained. |

---

## 2. What was verified, and what was not

Verification matters here because several items were written but could not be
exercised in the environment where they were produced.

### Verified on the development machine

- `doctor.py` — all seven sections pass.
- F-011 / F-012 — the application starts; missing configuration is reported by
  name at startup.
- `docker-compose.yml` — attaches to the pre-existing volume; row counts
  unchanged after switching (100 users, 37 museums, 14,922 nomenclature rows).
- KaTeX fix — the Equations lesson renders.
- `.dockerignore` — appended correctly, `**/.env` still present.

### Not verified

- **`Dockerfile` has never been built.** The `apt-get install nodejs npm` step
  is the most likely to need adjustment.
- **`.vscode/launch.json` has never been run.** Press F5 and confirm.
- **`updates/DEVENV.md` was written from this session, not from a clean run.** Its
  real test is a first-time setup on another machine.

---

## 3. Defects root-caused

### KaTeX 500s — FIXED

Lessons containing maths returned 500; all other pages rendered. Traceback
ended at `markdown_katex/wrapper.py` with `NotImplementedError: Platform not
supported, katex binary not found`.

`markdown_katex` shells out to a `katex` binary. The binaries it bundles are
**x86_64 only** — `x86_64-Darwin`, `x86_64-Linux`, `x86_64-Windows` — with no
arm64 build. On Apple Silicon it therefore fails, but only on the code path
that maths content reaches.

Fixed with `npm install -g katex`, which puts a native binary on PATH;
`markdown_katex` prefers that over its bundled copy. Now checked by `doctor.py`
section 7 and documented as a prerequisite in `updates/DEVENV.md`.

> This is architecture-sensitive and worth carrying into the deployment
> discussion: ARM instances (AWS Graviton, Azure Ampere) are cheaper and
> increasingly default, and this dependency fails on them unless Node and katex
> are installed properly in the image. The rewritten `Dockerfile` does this.

### Images not displaying — ROOT-CAUSED, NOT FIXED

Two independent causes:

1. `onemuseum/images/routes.py` resolves its folder with
   `os.path.realpath('./static/images')` — relative to the **current working
   directory**, not the package. Run from the project root this resolves to
   `<root>/static/images`, which does not exist. The route then falls back
   silently to `_missing_.jpg`, so there is no error to observe.
2. The image files are not in the repository. `onemuseum/static/images/`
   contains only `_missing_.jpg`.

Fixing the path alone will not make images appear. Where the images should live
— repository, mounted volume, or object storage — is a deployment decision, not
a bug fix, and is left open deliberately.

---

## 4. Dockerfile: what was wrong

The previous file was VS Code's auto-generated scaffold from around 2020. It
would not have built.

| Defect | Consequence |
| --- | --- |
| `CMD [... "app:app"]` | `app.py` no longer exists. Gunicorn fails immediately. |
| `python:3.8-slim-buster` | Debian buster is EOL, so `apt-get` fails; Python 3.8 cannot run the pinned Flask 3.1.3, so `pip install` fails. |
| No Node or katex | Maths pages 500 inside the container even on x86 — the bundled binary is a Node bundle and the slim image has no Node runtime. |
| CRLF line endings throughout | Can produce obscure failures in `RUN` steps. |

Rewritten with Python 3.12-slim, Node and a native katex, `wsgi:app` as the
entrypoint, requirements installed before the source copy for layer caching,
the unprivileged `appuser` retained, and gunicorn logging to stdout.

**npm is deliberately not purged after installing katex** — purging it can
remove the global katex package with it, silently reintroducing the bug. The
image is slightly larger as a result.

### Known limitation

A container cannot reach the database at `127.0.0.1` — that is the container's
own loopback, not the host's. Running the image will need
`host.docker.internal` (Docker Desktop) or both containers on a shared Compose
network. This is unresolved and is a deployment concern.

---

## 5. Outstanding before the next session

Small items left from today:

1. **`.env.example` needs two corrections** — a stray `EOF` on the last line
   (leftover from a heredoc) and `MYSQLCONN_DATABASE=onemuseum`, which should be
   `onemuseum2`. Also add `MARIADB_ROOT_PASSWORD` (required by
   `docker-compose.yml`) and the three `MAIL_*` variables. This is the file a
   new developer copies, so a wrong default costs them a confused first run.
2. **Rotate the development root password.** Because the Docker volume is
   already initialised, `MARIADB_ROOT_PASSWORD` is **ignored** on any new
   container — the environment variable will not do it. Use `ALTER USER` inside
   the running container.
3. **Build the image** — `docker build -t onemuseum:dev .`

Then, in the next increment: F-014 (least-privilege DB user), followed by F-013
and F-015.

---

## 6. Git

`.vscode/` and `settings.json` are both in `.gitignore`, so the two debug
configuration files **will not be committed** unless that is changed
deliberately. Decide before committing:

- **Leave them ignored** — each developer creates their own. Simplest; the
  configuration is described in `updates/DEVENV.md`.
- **Commit them** — shared debug configuration, one less setup step. Requires
  un-ignoring the two files specifically:

  ```
  # append to .gitignore
  !.vscode/launch.json
  !.vscode/settings.json
  ```

  (Negation patterns only work if the parent directory is not itself excluded,
  so `.vscode/` in `.gitignore` must become `.vscode/*` first.)

### Before committing — confirm no secrets are staged

`.env` is gitignored, but verify rather than assume:

```
git status --porcelain
git check-ignore -v .env
```

The first must not list `.env`. The second must report the rule that ignores
it. If `.env` appears as untracked, stop and fix `.gitignore` before going
further.

Then check the staged content itself:

```
git diff --cached
```

Confirm no real `SECRET_KEY`, password, or credential appears. `.env.example`
must contain placeholders only.

### Commit

Work on a branch rather than directly on the main line:

```
git checkout -b v1.0.3-config
git add -A
git status
```

Review what `git status` lists before committing. Then:

```
git commit -m "v1.0.3: environment configuration and diagnostics

F-011: load .env in code via python-dotenv; restore MYSQLCONN_* to
environment variables; add committed .env.example template.

F-012: validate required configuration in create_app() and refuse to
start, naming every missing variable at once rather than failing
identically on every request.

Add doctor.py, a standalone seven-section diagnostic that imports
nothing from the onemuseum package so it works when the app cannot
start: .env discovery, required variables, DB driver, connection,
stored procedures, read access, and KaTeX rendering.

Add docker-compose.yml for the development MariaDB, declaring the
existing data volume as external.

Rewrite Dockerfile: it referenced a removed app.py and used an EOL
base image that cannot run the pinned Flask version. Now installs
Node and a native katex, without which pages containing maths return
500 inside the container.

Add updates/DEVENV.md and update docs/CONFIG.md.

Fixes maths-lesson 500s on arm64 (no bundled katex binary for that
architecture; a native katex on PATH takes precedence).

Refs: D-006, F-011, F-012"
```

### Verify the tree is clean, then merge

```
git status
python doctor.py
```

`doctor.py` should report all checks passed before you merge. Then:

```
git checkout main
git merge v1.0.3-config
```

### Tag

```
git tag -a v1.0.3 -m "v1.0.3: environment configuration and diagnostics"
```

### Push

```
git push origin main
git push origin v1.0.3
```

If the branch was pushed while in progress, delete it once merged:

```
git push origin --delete v1.0.3-config
git branch -d v1.0.3-config
```

### If something was committed that should not have been

If a credential reaches a commit, changing the file in a later commit does not
remove it — it stays in history. Rotate the exposed credential first, then deal
with the history. For a local-only branch, `git reset --soft HEAD~1` unstages
the commit while keeping the changes. If it has already been pushed, rewriting
shared history is disruptive; rotating the credential is the reliable remedy.

The development root password is due for rotation in any case (section 5).
