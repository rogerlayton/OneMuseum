# APPLY — landing v1.0.1

Do this in order. The critical rule: **tag `v0.11` on the CURRENT
(un-restructured) code FIRST**, then apply the v1.0.1 tree. If you tag v0.11
after restructuring, the preserved "old version" will wrongly contain the new
structure.

Assumes a working directory that is a git repo, currently holding the code
that matches tag intent v0.11. Adjust paths/remote names to your setup.

---

## Step 0 — Preflight
- You have renamed the authoritative `requirements3.txt` back — irrelevant now,
  since v1.0.1 replaces the requirements files anyway; just confirm you are on
  the branch you want (e.g. `main`) and know your remote name (`origin`).
- Close the app / any file locks (Windows).
- **Do not** have the repo inside a cloud-synced folder with a live `.git`
  (methodology §4). If it is, move it out first.

## Step 1 — Commit current state, then TAG v0.11 (the preserved spec)
Run from the repo root, with the code AS-IS (before applying v1.0.1):

```
git add .
git commit -m "v0.11 — preserved working version prior to restructure"
git tag v0.11
git push
git push --tags
```

If the working tree is already clean/committed and represents v0.11, you may
skip the add/commit and just `git tag v0.11 && git push --tags`.

> Checkpoint: `git tag` shows `v0.11`. This is your fallback point.

## Step 2 — Apply the v1.0.1 tree
The delivered zip (`OneMuseum-v1.0.1.zip`) contains the FULL restructured
project. Because the restructure moves files into `onemuseum/` and deletes
several, the safe way is a clean replace of tracked content:

1. Extract the zip to a temp location.
2. In the repo, remove the old working files (keep `.git/`):
   - Easiest reliable way:
     ```
     git rm -r --quiet .            # stages deletion of all tracked files
     ```
     (This does NOT touch `.git/`. Untracked files, if any, remain — remove
     manually if needed.)
3. Copy the extracted v1.0.1 contents into the repo root (so you get
   `onemuseum/`, `wsgi.py`, `tests/`, `docs/`, `updates/`, `requirements.txt`,
   `requirements-dev.txt`, `SQL/`, `_DevNotes/`, etc.).
4. Stage everything:
   ```
   git add .
   ```

> Checkpoint: `git status` should show the restructure — old paths deleted,
> new `onemuseum/...` paths added.

## Step 3 — Verify BEFORE committing (the eyeball)
In your real environment (with MariaDB env vars set):

```
python -m venv .venv && . .venv/bin/activate      # or your usual env
pip install -r requirements.txt
pip install -r requirements-dev.txt               # for tests
```

Launch:
```
gunicorn wsgi:app        # or: flask --app wsgi run   (dev)
```

Then in a browser, confirm these render as in v0.11:
- a browser list page (`/b/<entity>`)
- a details page (`/d/...`)
- a categories page (`/c/...`)
- a menu / home page

Run the tests (DB-backed ones need MariaDB reachable):
```
pytest -q
```
Expected: config/cache/sdf/docs tests pass; `test_menus` fails (B-002,
pre-existing, test-only — safe to ignore for this release); dbutils/favourites
tests pass IF MariaDB is reachable and seeded.

Also specifically exercise anything that calls `dbUpdate` (B-001 fix), since
that path never worked before.

> If anything renders differently from v0.11, STOP. Do not commit. Note what
> differs and hand back — do not "fix forward" blind.

## Step 4 — Commit and TAG v1.0.1
Only after Step 3 passes your eyeball:

```
git add .
git commit -m "v1.0.1 — cleanup & Flask-layout restructure + Flask 3 deps (D-001..D-003)"
git tag v1.0.1
git push
git push --tags
```

(The full commit message is in updates/CHANGES-v1.0.1.md if you want the long
form.)

## Step 5 — Cut the session archive (outside the repo)
Only after a verified-clean commit:

```
git archive HEAD --format=zip -o ../OneMuseum-v1.0.1.zip
```

> `git archive HEAD` captures the COMMIT, not the working dir. Because you
> committed in Step 4, this is correct. Written OUTSIDE the repo per §4.

---

## Rollback
If Step 3 fails and you want to abandon:
```
git checkout -- .        # discard unstaged changes
git reset --hard v0.11   # return working tree to the preserved version
```
(Only do the hard reset if you have not committed v1.0.1 and are sure.)
