"""Docs-in-step-with-code check for configuration (methodology sec 2).

Fails if the environment variables read by onemuseum/config.py drift out of
step with those documented in docs/CONFIG.md. Keeps the config reference
honest without manual policing.

The contract:
  * Every `os.environ.get('NAME')` in config.py MUST be listed in the
    "## Environment variables" table of docs/CONFIG.md (as `NAME`).
  * Every env var documented in that table MUST exist in config.py.

If this test fails, update whichever side is stale, in the SAME commit.
"""
import os
import re

HERE = os.path.dirname(__file__)
ROOT = os.path.abspath(os.path.join(HERE, os.pardir))
CONFIG_PY = os.path.join(ROOT, "onemuseum", "config.py")
CONFIG_MD = os.path.join(ROOT, "docs", "CONFIG.md")


def _env_vars_in_code():
    with open(CONFIG_PY, encoding="utf-8") as f:
        src = f.read()
    return set(re.findall(r"os\.environ\.get\('([A-Z0-9_]+)'\)", src))


def _env_vars_in_docs():
    with open(CONFIG_MD, encoding="utf-8") as f:
        md = f.read()
    # Grab the block after the "## Environment variables" heading up to the
    # next "## " heading, and pull `NAME` backtick-quoted identifiers from it.
    m = re.search(r"##\s+Environment variables\s*(.*?)(?:\n##\s|\Z)", md, re.S)
    if not m:
        return set()
    block = m.group(1)
    return set(re.findall(r"`([A-Z0-9_]+)`", block))


def test_config_env_vars_match_docs():
    code = _env_vars_in_code()
    docs = _env_vars_in_docs()

    missing_in_docs = code - docs
    missing_in_code = docs - code

    assert not missing_in_docs, (
        "config.py reads env vars not documented in docs/CONFIG.md: "
        f"{sorted(missing_in_docs)}"
    )
    assert not missing_in_code, (
        "docs/CONFIG.md documents env vars not present in config.py: "
        f"{sorted(missing_in_code)}"
    )
