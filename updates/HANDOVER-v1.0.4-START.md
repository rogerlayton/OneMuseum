# HANDOVER — v1.0.4 (START)

Written at the close of v1.0.3, 2026-07-23. Repository is at tag **`v1.0.3`**,
commit `1739538`, pushed to origin. Working tree clean.

Full detail of the previous increment is in `updates/APPLY-v1.0.3.md`. This
document is the starting point for the next one.

---

## 1. Where things stand

The development environment works. `python doctor.py` reports all seven
sections passing on the primary machine, the application starts, and pages
render — including maths lessons, which had been failing.

What changed in v1.0.3:

- **F-011** — configuration is read from a `.env` file at the project root,
  loaded by `load_dotenv()` in `onemuseum/config.py` at import time. It no
  longer depends on shell exports that die with the terminal.
- **F-012** — missing required configuration now stops startup with a message
  naming every absent variable, rather than producing an identical unreadable
  500 on every request.
- **`doctor.py`** — a standalone seven-section diagnostic at the project root.
  It imports nothing from the `onemuseum` package, so it still works when the
  application cannot start.
- **`docker-compose.yml`** — declarative replacement for the manual
  `docker run`, carrying the essential `--lower-case-table-names=1` flag and
  the `mariadb:10.6` pin.
- **`Dockerfile`** — rewritten. The previous file could not have built.
- **`updates/DEVENV.md`** — merged, not replaced.
- **`.vscode/`** — debug configurations, now committed.

---

## 2. Verified, and not verified

This distinction matters more than usual here, because several items are
committed to the repository but have never been executed. Being in the repo is
not evidence that they work.

### Verified on the primary machine

- `doctor.py` — all seven sections pass.
- F-011 / F-012 — the application starts; missing configuration is named at
  startup.
- The KaTeX fix — the Equations lesson renders.
- `docker compose config` validates and resolves `MARIADB_ROOT_PASSWORD`.

### NOT verified

- **The `Dockerfile` has never been built.** `docker build -t onemuseum:dev .`
  has not been run. The `apt-get install nodejs npm` step is the most likely to
  need adjustment.
- **`.vscode/launch.json` has never been run.** Press F5 and confirm the three
  configurations work. Requires the VS Code Python extension for `debugpy`.
- **`updates/DEVENV.md`'s cold-start procedure has never been executed end to
  end.** This is the most significant gap. Every other outstanding item is
  scoped work; this one is a document asserting a sequence works when nobody
  has followed it in order. The second developer's first setup is its real
  test — if it fails somewhere, capture that rather than working around it.
- **`docker compose up` has never successfully created the container.** The
  running MariaDB is still the original one from the manual `docker run` (up 29
  hours at time of writing, `mariadb:10.6`). An attempt to switch hit a name
  conflict and created nothing; nothing was destroyed. Reconciling the two is
  cosmetic — both are the same image — but it means the Compose path is
  untested.

---

## 3. Deferred work, in order

These were in scope for v1.0.3 and deliberately carried forward.

1. **F-014 — least-privilege database user.** The application currently
   connects as `root`. Replace with a user holding only the privileges it
   needs. **Do this first**: it changes the credentials the error handling in
   F-013 will be reporting on, and it produces the credential to hand to the
   second developer, rather than sharing `root`.
2. **F-013 — database connection error handling.** `dbOpen()` in
   `onemuseum/dbutils.py` currently prints to stdout on failure and then falls
   through to `return DBCONN`, which was never assigned — producing an
   `UnboundLocalError` that masks the real cause.
3. **F-015 — minimal diagnostic logging.**

---

## 4. Immediate housekeeping

Small items left over from v1.0.3.

- **Rotate the development root password.** The current value appears in git
  history from earlier commits, so removing it from `config.py` does not erase
  it. Because the Docker volume is already initialised,
  `MARIADB_ROOT_PASSWORD` is **ignored** on any new container — the environment
  variable will not do it. Use `ALTER USER` inside the running container.
- **Build the image** — `docker build -t onemuseum:dev .`
- **Test the debug configurations** — F5 in VS Code.

---

## 5. Bugs

### Images do not display — ROOT-CAUSED, NOT FIXED

Two independent causes, both confirmed:

1. `onemuseum/images/routes.py` resolves its image folder with
   `os.path.realpath('./static/images')` — relative to the **current working
   directory**, not the package. Run from the project root this resolves to
   `<root>/static/images`, which does not exist. The route then falls back
   silently to `_missing_.jpg`, so nothing is logged and no error surfaces.
2. The image files are not in the repository. `onemuseum/static/images/`
   contains only `_missing_.jpg`.

**Fixing the path alone will not make images appear.** Where the files should
live — repository, mounted volume, or object storage — is an open design
question, and the schema already has `digitalobjects` and
`digitalrepositories` tables that may be the intended answer. This is worth
discussing with the second developer before implementing: five-year-old context
on how images were meant to resolve may be worth more than fresh debugging.

### Maths lessons return 500 (B-004) — FIXED

`markdown_katex` shells out to a `katex` binary. The binaries it bundles are
**x86_64 only** — `x86_64-Darwin`, `x86_64-Linux`, `x86_64-Windows` — with no
arm64 build, so on Apple Silicon it raised `NotImplementedError` and any page
containing maths returned a 500 while everything else rendered normally.

Fixed with `npm install -g katex`, which puts a native binary on PATH;
`markdown_katex` prefers that over its bundled copy. Now a documented
prerequisite and checked by `doctor.py` section 7.

**This will not reproduce on x64 Windows** — the bundled Windows binary works
there. That is a reason to keep the check rather than remove it: the failure is
invisible on some machines and fatal on others.

### Still open from earlier increments

- **`tests/test_spec_sdf.py::test_menus` fails** (B-002) — pre-existing,
  test-only.
- **Hardcoded sign-in bypass** in `onemuseum/users/routes.py` (B-003) —
  scheduled for removal in D-007 and **must** be gone before public launch.
- **Footer shows an old version string** — cosmetic, hardcoded.

---

## 6. Open decisions

- **Where images should live.** See section 5.
- **Cloud platform — Azure or AWS.** Deliberately not decided. The technical
  differences are marginal for a single Flask app with MariaDB and image
  storage; what should decide it is the second developer's expertise, cost at
  actual scale, any nonprofit or educational credits available, and data
  residency requirements. This is the decision she is qualified to make, and
  settling it beforehand would waste that.
- **ARM versus x86 instances.** Relevant and concrete: ARM (AWS Graviton, Azure
  Ampere) is cheaper and increasingly default, and the KaTeX dependency fails on
  it unless Node and a native `katex` are installed in the image. The rewritten
  `Dockerfile` does this. Worth raising explicitly rather than discovering in
  deployment.
- **F-001 / Postgres migration** interacts with the cloud choice and should be
  discussed alongside it, not settled separately.
- **Container networking.** A container cannot reach the database at
  `127.0.0.1` — that is its own loopback. Running the application image needs
  `host.docker.internal` or a shared Compose network. Unresolved; part of F-002.

---

## 7. Notes on process

Two things cost disproportionate time in v1.0.3 and are worth avoiding:

- **Multi-line heredocs pasted into the terminal failed repeatedly** — three
  times, once leaving a `.env` containing the shell commands themselves, which
  then produced confusing dotenv parse errors. Downloading files is more
  reliable than pasting blocks.
- **Files with leading dots** (`.env.example`, `.dockerignore`) do not always
  survive a browser download or appear in Finder. Cmd+Shift+. reveals hidden
  files on macOS.

Also worth recording: `docs/DEVENV.md` did not exist, but `updates/DEVENV.md`
did — a substantial cold-start document that was nearly overwritten before the
mismatch was noticed. It contained facts recorded nowhere else, including the
`--lower-case-table-names=1` requirement. **Check `updates/` as well as `docs/`
before concluding a document is missing.**
