# OneMuseum — developer command runner
#
# Run `make` on its own to list the available targets.
#
# This file encodes environment findings from
# updates/HANDOVER-v1.0.4-PROGRESS.md so they are enforced by tooling rather
# than remembered:
#   - port 5000 is taken by AirPlay Receiver on macOS, so we use 5001
#
# NOTE: recipe lines MUST be indented with a TAB, not spaces.
# Requires GNU Make. macOS ships 3.81; this file avoids anything newer.

PORT ?= 5001
URL  ?= http://127.0.0.1:$(PORT)/
PY   ?= python

.DEFAULT_GOAL := help
.PHONY: help open

help:  ## List available targets
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) \
	  | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}'

# --- testing in the browser -----------------------------------------------

# Flask's dev server runs in the FOREGROUND and holds this terminal until
# Ctrl-C. So the browser is launched from a background subshell that waits a
# moment for the port to be bound -- otherwise it fires first and shows
# connection-refused. Ctrl-C stops Flask; the browser tab stays open.
open:  ## Run Flask and open the app in the browser
	@echo "starting OneMuseum on $(URL)  (Ctrl-C to stop)"
	@( sleep 2; open "$(URL)" ) &
	@$(PY) -m flask --app wsgi run --port $(PORT) --debug

# --- admin (terminal-only, isolated from the web UI) ----------------------

create-user:  ## Create a test user (prompts for email, username, password)
	@$(PY) -m flask --app wsgi create-user

list-users:  ## List existing users
	@$(PY) -m flask --app wsgi list-users

reset-password:  ## Reset a user's password (prompts for email + new password)
	@$(PY) -m flask --app wsgi reset-password

check-login:  ## Verify an email + password without logging in (prompts)
	@$(PY) -m flask --app wsgi check-login

# --- database (see scripts/db.sh for the connection details it encodes) ----

db-shell:  ## Open a mysql prompt on the dev database
	@bash scripts/db.sh shell

db-backup:  ## Back up the dev database volume to ~/ (tarball, always works)
	@bash scripts/db.sh backup

db-file:  ## Run a .sql file: make db-file FILE=SQL/xxx.sql
	@test -n "$(FILE)" || { echo "usage: make db-file FILE=SQL/xxx.sql"; exit 1; }
	@bash scripts/db.sh file "$(FILE)"

# --- release archive --------------------------------------------------------

# Export a clean zip of committed files at the given ref. git archive respects
# .gitignore, so .env / .venv / caches are never included. VERSION sets both the
# filename and which ref is exported; defaults to the latest tag.
#   make archive                 -> uses the most recent tag
#   make archive VERSION=v1.0.4  -> exports that tag, names the file for it
archive:  ## Zip committed files at a tag: make archive VERSION=v1.0.4
	@VER="$(VERSION)"; \
	if [ -z "$$VER" ]; then VER=$$(git describe --tags --abbrev=0); fi; \
	SAFE=$$(echo "$$VER" | sed 's/\./_/g'); \
	OUT="../OneMuseum-$$SAFE-HEAD.zip"; \
	echo "archiving $$VER -> $$OUT"; \
	git archive --format=zip --prefix="OneMuseum-$$SAFE/" -o "$$OUT" "$$VER"; \
	ls -lh "$$OUT"
