# Database access — dev container runbook

This exists because connecting to the laptop dev MariaDB by hand turned into a
two-hour ordeal once, entirely from traps that are invisible until you hit
them. Everything below is now encoded in `scripts/db.sh`; this document
explains *why*, so the tooling isn't cargo-culted.

## TL;DR — use the helper, not raw docker commands

    make db-shell                  # interactive prompt
    make db-backup                 # volume tarball to ~/  (always works)
    make db-file FILE=SQL/x.sql    # run a script
    bash scripts/db.sh query "SELECT COUNT(*) FROM users;"

The helper reads credentials from `.env`, connects the one way that works, and
never asks you to type or expose a password.

## The traps (each cost real time to discover)

1. **Prompt + redirect sends no password.**
   `docker exec ... mysqldump -u root -p ... > file` prints "Enter password:"
   but the redirect and non-interactive exec mean your typed password never
   reaches it. It connects with *no* password and fails: `using password: NO`.
   Fix: pass the password without a prompt, or run interactively with `-it`.

2. **Socket vs TCP are different grants.**
   `docker exec ... mysql` connects over the UNIX SOCKET, which MariaDB treats
   as host `localhost`. The app connects over **TCP to 127.0.0.1**. The app
   user (`onemuseum_app`) is granted on `'%'` in a way that matches TCP but is
   denied on the socket. Symptom: `Access denied for user
   'onemuseum_app'@'localhost'` even though the app works fine.
   Fix: always connect with `-h 127.0.0.1 --protocol=TCP`.

3. **Retyped passwords are error-prone.**
   Several "access denied (using password: YES)" failures were simply the
   wrong password typed at the prompt. The reliable move is to read it straight
   from `.env` and never retype it. The helper does this.

4. **The app user lacks admin privileges.**
   `onemuseum_app` is missing `LOCK TABLES` and `SHOW VIEW`, so a plain
   `mysqldump` dies partway (`SHOW VIEW command denied ... biographydetails`).
   The database uses views, which need `SHOW VIEW` to dump.
   Fix for logical dumps: `--single-transaction --skip-lock-tables`, or dump as
   root. Better: don't rely on the app user for backups at all — use the volume
   tarball (`make db-backup`), which never authenticates to MariaDB.

5. **The container's root password is a lie.**
   `docker inspect` shows `MARIADB_ROOT_PASSWORD=devroot`, but that env var is
   only applied on FIRST init, when the data volume is created. This volume
   pre-existed, so the real root password is whatever it was initialised with —
   unknown and unrecovered. `root` over TCP fails. Root is only reachable via
   the local socket (`docker exec -it onemuseum-mariadb mysql -u root`), which
   the MariaDB image authenticates by `unix_socket` (no password).

## Backups — two kinds, know which you have

- **Volume tarball** (`make db-backup`): filesystem copy of `/var/lib/mysql`.
  Immune to every privilege trap because it never logs in. ~10 MB. This is the
  recommended dev backup. Restore by stopping the container and untarring back
  over the volume:

      docker stop onemuseum-mariadb
      docker run --rm --volumes-from onemuseum-mariadb -v ~/:/backup alpine \
        sh -c 'cd / && tar xzf /backup/onemuseum-volume-backup-YYYY-MM-DD.tar.gz'
      docker start onemuseum-mariadb

- **Logical .sql dump** (`bash scripts/db.sh dump`): human-readable, needs root
  over the socket. Use when you want a diffable/greppable dump.

**A 0-byte or tiny backup file is not a backup.** Always verify:

      ls -lh ~/onemuseum-volume-backup-*.tar.gz     # expect several MB
      tar tzf ~/onemuseum-volume-backup-*.tar.gz | head   # lists var/lib/mysql/...

## Running destructive scripts safely

Scripts like `SQL/DEV-wipe-users.sql` are transaction-wrapped. Note a subtlety:
when piped through `docker exec -i` as one session, a script that ends WITHOUT
`COMMIT` rolls back on session close — so the first run is effectively a dry
run that proves the SQL is correct (no errors, expected counts) while changing
nothing. Add `COMMIT` only once the dry run looks right.

Always `make db-backup` before running anything destructive.

## For the rebuild (F-014 credential model)

This whole runbook is a symptom. The rebuilt environment should:
- provision the app user with an explicit, documented, least-privilege grant,
  host-scoped rather than `'%'`;
- provision a *separate* admin/migration user with the rights backups and
  schema changes need (LOCK TABLES, SHOW VIEW), so admin work doesn't fight the
  app user;
- set and RECORD the root password in a password manager at creation, so it's
  never unknown;
- not carry this volume (and its lost root password) forward.
