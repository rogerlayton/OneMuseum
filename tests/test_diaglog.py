"""F-015 (D-006) — administrator diagnostic logging.

These tests need no live database. They exercise diaglog directly and assert
the D-006 contract:

  * errors are ALWAYS logged, regardless of DIAG_LOGGING;
  * verbose diagnostic lines appear ONLY when DIAG_LOGGING is on;
  * every record is a single physical line (pipe-delimited);
  * configure_logging is idempotent (no duplicate handlers);
  * a DBConnectionError message (which never contains the password — F-013)
    is what reaches the log on the outage path.
"""

import logging

import pytest

from onemuseum import diaglog
from onemuseum.config import env_truthy


class _Cfg(dict):
    """A stand-in for app.config: a plain dict is enough for diaglog."""


@pytest.fixture(autouse=True)
def _reset_logger():
    """Each test gets a clean 'onemuseum' logger with no leftover handlers or
    the idempotency flag from a previous test."""
    logger = logging.getLogger(diaglog.LOGGER_NAME)
    for h in list(logger.handlers):
        logger.removeHandler(h)
    if hasattr(logger, diaglog._CONFIGURED_FLAG):
        delattr(logger, diaglog._CONFIGURED_FLAG)
    logger.setLevel(logging.NOTSET)
    yield
    for h in list(logger.handlers):
        logger.removeHandler(h)


# --- env_truthy (the shared flag parser) ---------------------------------

@pytest.mark.parametrize("value,expected", [
    ("1", True), ("true", True), ("TRUE", True), ("Yes", True), ("on", True),
    ("0", False), ("false", False), ("no", False), ("off", False),
    ("", False), ("banana", False),
])
def test_env_truthy(monkeypatch, value, expected):
    monkeypatch.setenv("SOME_FLAG", value)
    assert env_truthy("SOME_FLAG") is expected


def test_env_truthy_unset_uses_default(monkeypatch):
    monkeypatch.delenv("SOME_FLAG", raising=False)
    assert env_truthy("SOME_FLAG", default=False) is False
    assert env_truthy("SOME_FLAG", default=True) is True


# --- oneline ---------------------------------------------------------------

def test_oneline_collapses_newlines():
    out = diaglog._oneline("line one\nline two\r\nline three")
    assert "\n" not in out and "\r" not in out
    assert out == "line one line two line three"


# --- error always logged, diag gated --------------------------------------

def test_error_logged_when_diag_off(tmp_path):
    log = tmp_path / "om.log"
    diaglog.configure_logging(_Cfg(DIAG_LOGGING=False, LOG_FILE=str(log)))
    diaglog.log_error("dbGetAll", "boom")
    text = log.read_text()
    assert "ERROR" in text
    assert "dbGetAll: boom" in text


def test_diag_suppressed_when_off(tmp_path):
    log = tmp_path / "om.log"
    diaglog.configure_logging(_Cfg(DIAG_LOGGING=False, LOG_FILE=str(log)))
    diaglog.log_diag("dbGetAll", "SELECT * FROM x")
    text = log.read_text()
    # the startup line is present, but the diagnostic one is not
    assert "SELECT * FROM x" not in text


def test_diag_emitted_when_on(tmp_path):
    log = tmp_path / "om.log"
    diaglog.configure_logging(_Cfg(DIAG_LOGGING=True, LOG_FILE=str(log)))
    diaglog.log_diag("dbGetAll", "SELECT * FROM x")
    text = log.read_text()
    assert "SELECT * FROM x" in text
    assert "DEBUG" in text


# --- one physical line per message ----------------------------------------

def test_one_line_per_message(tmp_path):
    log = tmp_path / "om.log"
    diaglog.configure_logging(_Cfg(DIAG_LOGGING=True, LOG_FILE=str(log)))
    diaglog.log_error("proc", "multi\nline\nerror")
    # find the error line and assert the payload did not split into three
    lines = [ln for ln in log.read_text().splitlines() if "ERROR" in ln]
    assert len(lines) == 1
    assert "multi line error" in lines[0]


# --- format has the four fields -------------------------------------------

def test_line_has_pipe_fields(tmp_path):
    log = tmp_path / "om.log"
    diaglog.configure_logging(_Cfg(DIAG_LOGGING=False, LOG_FILE=str(log)))
    diaglog.log_error("where", "what")
    line = [ln for ln in log.read_text().splitlines()
            if "where: what" in ln][0]
    # timestamp | LEVEL | route | message  -> at least three pipes
    assert line.count("|") >= 3
    assert "| ERROR |" in line
    # no request context in a bare call -> route is '-'
    assert "| - |" in line


# --- idempotent configuration ---------------------------------------------

def test_configure_is_idempotent(tmp_path):
    log = tmp_path / "om.log"
    cfg = _Cfg(DIAG_LOGGING=False, LOG_FILE=str(log))
    diaglog.configure_logging(cfg)
    diaglog.configure_logging(cfg)
    diaglog.configure_logging(cfg)
    logger = logging.getLogger(diaglog.LOGGER_NAME)
    assert len(logger.handlers) == 1
    diaglog.log_error("x", "once")
    assert log.read_text().count("x: once") == 1


# --- outage path carries the DBConnectionError message, no password --------

def test_db_outage_logs_message_without_password(tmp_path):
    from onemuseum.dbutils import DBConnectionError
    log = tmp_path / "om.log"
    diaglog.configure_logging(_Cfg(DIAG_LOGGING=False, LOG_FILE=str(log)))
    # F-013 guarantees the message never contains the password; simulate one.
    exc = DBConnectionError(
        "Cannot connect to the database as app@127.0.0.1:3306/onemuseum2. "
        "Access denied.")
    diaglog.log_db_outage(exc)
    text = log.read_text()
    assert "DB-OUTAGE" in text
    assert "onemuseum2" in text
    assert "password" not in text.lower()
