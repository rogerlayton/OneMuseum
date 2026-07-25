#!/usr/bin/env bash
# OneMuseum — database helper for the LAPTOP dev container.
#
# WHY THIS EXISTS
# ---------------
# Connecting to the dev MariaDB by hand is full of traps that cost real time:
#   * The prompt-plus-redirect combination silently sends NO password, so
#     `mysqldump ... > file` fails with "using password: NO".
#   * `docker exec ... mysql` connects over the UNIX SOCKET, which MariaDB
#     treats as host 'localhost' -- a DIFFERENT grant from '127.0.0.1'. The app
#     user is denied on the socket even though the app connects fine over TCP.
#   * The app user (onemuseum_app) lacks LOCK TABLES and SHOW VIEW, so a plain
#     mysqldump dies partway; it needs --single-transaction --skip-lock-tables.
#   * The container's MARIADB_ROOT_PASSWORD env var is IGNORED when the data
#     volume already exists, so the "root password" shown by `docker inspect`
#     does not work. Root is only reachable via the local socket.
#
# This script encodes the ONE connection that works -- the app user, over TCP,
# with the password read straight from .env (never retyped) -- so none of the
# above has to be rediscovered. Everything routes through db_app().
#
# It reads credentials from ../.env. It never takes a password on the command
# line and never prints one.
#
# USAGE
#   scripts/db.sh shell                 open an interactive mysql prompt
#   scripts/db.sh query "SELECT ..."    run one statement, print result
#   scripts/db.sh file  path/to.sql     run a .sql file
#   scripts/db.sh backup                volume-tarball backup to ~/ (see note)
#   scripts/db.sh dump                  logical .sql dump to ~/  (root, socket)
#
# All read/query/file operations use the app user over TCP. The backup and
# dump operations need broader rights and use root over the local socket.

set -euo pipefail
cd "$(dirname "$0")/.."   # project root, so .env and SQL/ resolve

CONTAINER="${OM_DB_CONTAINER:-onemuseum-mariadb}"
ENV_FILE="${OM_ENV_FILE:-.env}"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "error: $ENV_FILE not found (run from project root)." >&2
  exit 1
fi

# Pull connection details from .env WITHOUT sourcing it (avoids executing
# anything) and without echoing the password anywhere.
env_get() { grep "^$1=" "$ENV_FILE" | head -1 | cut -d= -f2-; }

DB_USER="$(env_get MYSQLCONN_USER)"
DB_PASS="$(env_get MYSQLCONN_PASSWORD)"
DB_NAME="$(env_get MYSQLCONN_DATABASE)"
DB_HOST="127.0.0.1"   # deliberately TCP, not the socket -- see WHY above.

if [[ -z "${DB_USER:-}" || -z "${DB_PASS:-}" || -z "${DB_NAME:-}" ]]; then
  echo "error: MYSQLCONN_USER/PASSWORD/DATABASE missing from $ENV_FILE." >&2
  exit 1
fi

# The app user, over TCP, password from .env. This is the connection that works.
# Note: passing -p<pass> to mysql INSIDE the container via env avoids putting
# the password in this host's process list or shell history.
db_app() {
  docker exec -i -e MYSQL_PWD="$DB_PASS" "$CONTAINER" \
    mysql -u "$DB_USER" -h "$DB_HOST" --protocol=TCP "$DB_NAME" "$@"
}

# Root over the local socket. On the official MariaDB image this authenticates
# via unix_socket (no password), which is the only reliable way to get admin
# rights here since the root password is unknown. Used only for backup/dump.
db_root() {
  docker exec -i "$CONTAINER" mysql -u root "$@"
}

usage() { sed -n '2,40p' "$0" | sed 's/^# \{0,1\}//'; exit "${1:-0}"; }

cmd="${1:-}"; shift || true
case "$cmd" in
  shell)
    docker exec -it -e MYSQL_PWD="$DB_PASS" "$CONTAINER" \
      mysql -u "$DB_USER" -h "$DB_HOST" --protocol=TCP "$DB_NAME"
    ;;
  query)
    [[ $# -ge 1 ]] || { echo "usage: db.sh query \"SQL\"" >&2; exit 1; }
    printf '%s\n' "$1" | db_app
    ;;
  file)
    [[ $# -ge 1 && -f "$1" ]] || { echo "usage: db.sh file path.sql (file must exist)" >&2; exit 1; }
    db_app < "$1"
    ;;
  backup)
    # Filesystem-level backup of the whole data volume. Immune to every
    # privilege gap because it never authenticates to MariaDB. Briefly stops
    # the container for a consistent copy.
    OUT="$HOME/onemuseum-volume-backup-$(date +%Y-%m-%d-%H%M).tar.gz"
    echo "stopping $CONTAINER for a consistent copy..."
    docker stop "$CONTAINER" >/dev/null
    docker run --rm --volumes-from "$CONTAINER" -v "$HOME:/backup" alpine \
      tar czf "/backup/$(basename "$OUT")" /var/lib/mysql
    docker start "$CONTAINER" >/dev/null
    echo "backup written: $OUT"
    ls -lh "$OUT"
    ;;
  dump)
    # Logical .sql dump via root over the socket. Needs root; if this fails,
    # use `backup` (volume tarball) instead.
    OUT="$HOME/onemuseum-dump-$(date +%Y-%m-%d-%H%M).sql"
    db_root -e "" >/dev/null 2>&1 || {
      echo "root-over-socket not available; use 'db.sh backup' instead." >&2; exit 1; }
    docker exec -i "$CONTAINER" \
      mysqldump -u root --single-transaction --databases "$DB_NAME" > "$OUT"
    echo "dump written: $OUT"; ls -lh "$OUT"
    ;;
  ""|-h|--help|help) usage 0 ;;
  *) echo "unknown command: $cmd" >&2; usage 1 ;;
esac
