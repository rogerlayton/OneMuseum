"""F-013 — dbOpen() connection failure handling.

These tests deliberately need NO live database. They monkeypatch
mysql.connector.connect to raise, which is the only way to exercise the
failure path reliably — a real database that is up cannot be made to fail
on demand, and one that is down fails the rest of the suite too.

The bug being guarded against: dbOpen() used to catch the connection error,
print it, and fall through to `return DBCONN` — never assigned. That raised
UnboundLocalError, which is not a mysql.connector.Error, so it escaped every
caller's except clause and surfaced from `finally: dbClose(DBCONN)` instead,
one frame away from the real fault and with the driver's message already
discarded by print().
"""

import mysql.connector
import pytest
from mysql.connector import errorcode

from onemuseum import dbutils
from onemuseum.config import Config
from onemuseum.dbutils import DBConnectionError, dbClose, dbExists, dbOpen


def _raise(errno, msg="driver detail"):
    """Return a connect() replacement that always fails with this errno."""
    def _connect(**kwargs):
        raise mysql.connector.Error(msg=msg, errno=errno)
    return _connect


@pytest.mark.parametrize("errno", [
    errorcode.ER_ACCESS_DENIED_ERROR,   # wrong credentials
    errorcode.ER_BAD_DB_ERROR,          # database does not exist
    errorcode.CR_CONN_HOST_ERROR,       # server unreachable / container down
    9999,                               # unmapped errno -> generic branch
])
def test_dbopen_raises_dbconnectionerror(monkeypatch, errno):
    """Every failure mode raises DBConnectionError, never UnboundLocalError."""
    monkeypatch.setattr(dbutils.mysql.connector, "connect", _raise(errno))
    with pytest.raises(DBConnectionError):
        dbOpen()


def test_dbopen_chains_the_driver_error(monkeypatch):
    """The original mysql.connector error is preserved as __cause__."""
    monkeypatch.setattr(
        dbutils.mysql.connector, "connect",
        _raise(errorcode.ER_ACCESS_DENIED_ERROR, "the real driver message"))
    with pytest.raises(DBConnectionError) as excinfo:
        dbOpen()
    assert isinstance(excinfo.value.__cause__, mysql.connector.Error)
    assert "the real driver message" in str(excinfo.value.__cause__)


def test_dbopen_names_the_connection_target(monkeypatch):
    """The message identifies which server/user/database was attempted."""
    monkeypatch.setattr(dbutils.mysql.connector, "connect",
                        _raise(errorcode.CR_CONN_HOST_ERROR))
    with pytest.raises(DBConnectionError) as excinfo:
        dbOpen()
    message = str(excinfo.value)
    assert Config.MYSQLCONN_USER in message
    assert Config.MYSQLCONN_HOST in message
    assert Config.MYSQLCONN_DATABASE in message


def test_dbopen_never_discloses_the_password(monkeypatch):
    """A connection error must not put the password in a log or a flash."""
    monkeypatch.setattr(dbutils.mysql.connector, "connect",
                        _raise(errorcode.ER_ACCESS_DENIED_ERROR))
    with pytest.raises(DBConnectionError) as excinfo:
        dbOpen()
    assert Config.MYSQLCONN_PASSWORD
    assert Config.MYSQLCONN_PASSWORD not in str(excinfo.value)


def test_caller_finally_does_not_mask_the_cause(monkeypatch):
    """The regression itself.

    dbExists() has `finally: dbClose(DBCONN)`. Before F-013 that raised its
    own UnboundLocalError, replacing the real error. The caller must now see
    DBConnectionError.
    """
    monkeypatch.setattr(dbutils.mysql.connector, "connect",
                        _raise(errorcode.ER_ACCESS_DENIED_ERROR))
    with pytest.raises(DBConnectionError):
        dbExists("Users", "email", "nobody@example.com")


def test_dbclose_tolerates_none():
    """Safe when dbOpen() raised and DBCONN was never bound."""
    dbClose(None)


def test_dbclose_tolerates_a_broken_connection():
    """Closing an already-closed connection stays silent, as documented."""
    class AlreadyClosed:
        def close(self):
            raise mysql.connector.Error(msg="already closed")

    dbClose(AlreadyClosed())


def test_dbopen_returns_the_connection_on_success(monkeypatch):
    """The success path is unchanged — callers still get the connection."""
    sentinel = object()
    monkeypatch.setattr(dbutils.mysql.connector, "connect",
                        lambda **kwargs: sentinel)
    assert dbOpen() is sentinel
