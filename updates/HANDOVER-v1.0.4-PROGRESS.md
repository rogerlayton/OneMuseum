# HANDOVER — v1.0.4 (PROGRESS)

Written 2026-07-24, mid-increment. Version remains **v1.0.4** — two of its
three planned items (F-013, F-015) are still outstanding, so this is a
progress record, not a close-out.

Supersedes nothing. Read `updates/HANDOVER-v1.0.4-START.md` first; this
records what has since been done and what was found along the way.

---

## 1. Completed this session

### Static asset cleanup (~76 MB)

`onemuseum/static/` reduced from 85 MB to 7.8 MB. 375 unreferenced Now UI Kit
theme images removed, verified by reference audit: every filename was checked
against all `.html`, `.css`, `.scss`, `.js`, `.py`, `.json`, `.md` and `.txt`
files in the project before deletion.

Kept, because they are referenced in live templates:

- `static/assets/img/` — `bg6.jpg`, `blurred-image-1.jpg`, `olivia.jpg`,
  `logo.png` (email template), `apple-icon.png` (`head.html`)
- `static/img/` — the two Unsplash photographs still in use,
  `staryellow.png`, `starempty.png`, `icons8-museum-30.png`

Untouched: `assets/css`, `assets/js`, `assets/scss`, `assets/fonts`,
`nucleoicons/` (all live), and `profile_pics/` (user data).

The generating script is `cleanup_static.sh` at the project root. It is
retained as a record of what was removed and why. **It contains a
Linux-only construct** — `stat -c%s`, which fails silently on macOS BSD
`stat` and reports 0 bytes. The deletions were unaffected. If the script is
ever reused, the portable form is:

```bash
stat -f%z "$p" 2>/dev/null || stat -c%s "$p"
```

**Git history was not rewritten.** The ~76 MB remains in `.git` and every
clone still pays for it. `git filter-repo` plus a force-push would remove it,
and doing so is cheap while only one person has cloned. It becomes disruptive
once the second developer has a working copy. This is a deliberate deferral,
not an oversight.

### F-014 — least-privilege database user (DONE)

The application no longer connects as MariaDB root.

`SQL/F-014-app-user.sql` creates `onemuseum_app` with exactly the privileges
the application uses, determined by auditing every SQL statement in
`onemuseum/`:

| Privilege | Why |
|---|---|
| `SELECT, INSERT, UPDATE, DELETE` | CRUD in `dbutils.py` and the route modules |
| `EXECUTE` | `callproc()` — `GenCategories`, `ChenhallDetails`, `GenDetails`, the `UPLOAD_*` family |

Not granted: `CREATE`, `DROP`, `ALTER`, `INDEX`, `GRANT OPTION`, `FILE`,
`SUPER`, `LOCK TABLES`, `REFERENCES`. There is no DDL anywhere in the
application — the 14 `CREATE` matches in the initial scan were all Python
comments. Schema changes continue to be applied from `SQL/` by hand, as root.

`REPLACE INTO` (5 uses) needs no separate privilege; it is covered by
`INSERT` + `DELETE`.

**No application code changed.** `onemuseum/config.py` was already fully
environment-driven, so this was a database and `.env` change only.

Verified:

- `SHOW GRANTS` returns exactly two lines — `USAGE ON *.*` (which conveys no
  privileges) and the scoped grant on `onemuseum2.*`
- `CREATE TABLE` as `onemuseum_app` fails with `ERROR 1142: command denied`
  — this failure is the point of the exercise
- Categories and Chenhall navigation both render, exercising two separate
  stored procedures and confirming `EXECUTE` landed
- `tests/test_dbutils_01.py`, `test_dbutils_02.py` and `test_favourites.py`
  pass against the restricted user

The script in the repository has `CHANGE_ME` as the password placeholder. The
real value is stored outside the repository. Note that `SQL/` is **not**
gitignored — a credential left in a `.sql` file would be committed with
nothing to flag it. A pre-commit secret scan belongs on the DevOps list.

**Host scoping is `'%'`, which is too loose for production.** It is correct
for development because the app reaches the container across Docker's bridge
from an unstable address, and the port is published only to `127.0.0.1`.
Tightening this to a specific host or subnet is production work, flagged in
the SQL file itself.

### Root password rotation (DONE)

The dev root password `devroot` — which appears in git history — has been
replaced. Both `'root'@'localhost'` and `'root'@'%'` were altered; the `%`
entry is the one `docker exec` authenticates against over TCP, and missing it
produces a confusing "the new password doesn't work" symptom.

Verified by hash comparison rather than by trial:

```sql
SELECT User, Host, PASSWORD('<the-password>') = authentication_string AS matches
FROM mysql.user WHERE User='root';
```

Both rows return `1`. This check is worth knowing: a leading or trailing space
inside the `IDENTIFIED BY` quotes is stored as part of the password and is
completely invisible at a prompt. It caused a false failure during this
session.

`MARIADB_ROOT_PASSWORD` has been removed from `.env`. It was only ever read by
the MariaDB container at first volume initialisation and has been inert since.
`tests/test_config_docs.py` still passes, confirming the variable was never in
`config.py`'s checked set and `docs/CONFIG.md` needs no corresponding change.

`devroot` has been cleared from shell history.

### A backup exists

`~/onemuseum-backup-2026-07-24.sql`, 10 MB, `--all-databases`, taken before
any of the above. This is the first backup of the development database. It
should be moved somewhere that is not the development laptop, and taking one
before destructive work should become routine rather than exceptional.

### Test suite runs clean — 19 passed

The suite had **never been executed in this environment**. Getting it running
surfaced three separate problems, described in section 2.

`tests/test_spec_sdf.py` line 44 had a genuine defect:

```python
for item in menu_spec.items      # dict method object, not iterable
for item in menu_spec['items']   # the list sdf_menu actually builds
```

`sdf_menu()` ends with `menu_spec.update(items=items)`, so `'items'` is a
key. The commented-out assertions immediately below reference
`item['title']`, `item['folder']`, `item['img']` — exactly the ITEM fields
built in `sdfutils.py`. The author knew the structure; it was a typo.

---

## 2. Environment findings

These are cold-start facts. None were documented, and each cost time to
diagnose. They belong in `docs/DEVENV.md`.

**Port 5000 is taken by AirPlay Receiver on macOS.** It is on by default in
recent versions and will reclaim the port after every reboot. Use
`flask --app wsgi run --port 5001`. Diagnose with `lsof -i :5000` —
`ControlCe` is AirPlay; `Python` is a stale Flask process.

**`requirements-dev.txt` had never been installed.** Its absence presents as
`ModuleNotFoundError: No module named 'flask_bcrypt'` when running `pytest`,
which is misleading — the real problem is that `pytest` itself is missing from
the venv, so the shell falls through to a system Python that cannot see the
venv's packages.

**Use `python -m pytest`, not bare `pytest`.** On this machine `which pytest`
resolves to `/Library/Frameworks/Python.framework/Versions/3.14/bin/pytest`
while the venv runs 3.12. `python -m pytest` guarantees the active
interpreter and is immune to PATH ordering.

**`pytest-flask==1.2.0` is incompatible with Flask 3** and breaks collection
with `ImportError: cannot import name '_request_ctx_stack'`. That symbol was
removed in Flask 2.3; the pin predates the D-003 Flask 3 bump and was never
revisited. **No test uses any pytest-flask fixture** — it is a dependency in
name only. It should be removed from `requirements-dev.txt`. Uninstalling it
locally is what allowed the suite to run.

The wider point: `requirements.txt` and `requirements-dev.txt` are mutually
incompatible as pinned, and this went unnoticed because the suite had never
been run here. `pytest==7.2.0` and the linting pins are also around two years
old and worth reviewing — separately, so that any breakage has one obvious
cause.

---

## 3. Outstanding

### Immediate

1. **F-013 — `dbOpen()` returns unassigned `DBCONN`.** Unchanged from the
   START handover, and now the next item. The `UnboundLocalError` masks the
   real database error, which would have made this session's credential work
   considerably harder to debug had anything gone wrong. Note the
   "DO NOT MESS WITH THIS MODULE" warning at the top of `dbutils.py` — the
   per-call open/close design is deliberate and is not what is being changed.
2. **F-015 — minimal diagnostic logging.**
3. **Remove `pytest-flask` from `requirements-dev.txt`.**
4. **`docs/BACKLOG.md`** does not list F-013, F-014 or F-015. They exist only
   in handover documents. The backlog is where someone would look.
5. **`docs/DEVENV.md`** needs the section 2 findings.

### Deferred, with reasons

- **`git filter-repo`** to purge the 76 MB from history. Cheap now, disruptive
  after the second developer clones.
- **Production host scoping** for `onemuseum_app`.
- **Pre-commit secret scanning.** `.env` is gitignored; `SQL/*.sql` is not.
- **`static/specs/menus/home copy.sdf`** is picked up by `os.walk` and tested
  as a real spec. Delete or move it before it drifts from `home.sdf`.
- **The guard pattern** in `tests/test_spec_sdf.py`:
  ```python
  if not os.path.exists(path):
      assert os.path.exists(path)
      return
  ```
  Works, but obscurely. `assert os.path.exists(path), f"missing: {path}"`
  does the same job and reports the path.
- **`test_menus` proves very little.** Its body is `assert True` with the real
  assertions commented out. It confirms the specs parse and have a non-empty
  title, and nothing more.

### Still not verified

Unchanged from the START handover, and worth restating because none of it was
touched this session:

- The `Dockerfile` has never been built.
- `.vscode/launch.json` has never been run.
- `updates/DEVENV.md`'s cold-start procedure has never been executed end to
  end. This session's environment findings are evidence for why that matters:
  three separate problems in the test tooling alone, none of them documented,
  all of which a genuine cold start would have caught.

---

## 4. Decisions taken this session

**The UI framework question was raised and deliberately parked.** The project
runs Now UI Kit PRO v1.3.1 on Bootstrap 4.3.1 — a 2019 theme on an
end-of-life framework. The preference is to move to a **home-grown**
Bootstrap 5 layer rather than another vendor theme, on the grounds that pinned
Python packages are declared and auditable while a theme's assets are just
files in the tree.

Parked rather than scheduled, because a framework migration serves neither of
the stated v1.0.4 goals, and because images still do not display (B-004) and
the hardcoded auth bypass (B-003) must go before launch. Those are launch
blockers; the theme is not. It is also a decision that should be made with the
second developer, who will maintain the templates.

Worth recording separately: **the old production at onemuseum.net is a legacy
artifact**, not a system these credentials touch. Production is to be rebuilt
from this work with a full DevOps structure. That reframes F-014 — it is not a
patch on an existing system but the first piece of the production credential
model, being built in development where mistakes are cheap. The never-executed
items above stop being loose ends and become the foundation of that work.

---

## 5. State

Version **v1.0.4**, in progress. Two of three planned items outstanding.

`docs/CONFIG.md` required no change — verified by
`tests/test_config_docs.py`, which passes.

Credentials for `root` and `onemuseum_app` are stored in a password manager,
along with the Docker volume name needed for container recovery. Recovery
instructions that live only in a chat window are not recovery instructions.
