"""F-018 (B-005) — email-confirmation sign-in gate.

These tests need no live database. They patch the user lookup and the password
check so only the gate branch in signin() is exercised, and assert the contract:

  * a user with a correct password but email_confirmed = False/None is BLOCKED
    (not logged in) and told to confirm their email;
  * a user with a correct password and email_confirmed = True is let through;
  * a wrong password never reaches the gate (unchanged behaviour).

The gate lives inside the password-success branch of signin(), above
login_user(). The hardcoded FORCED SIGN IN bypass is deliberately NOT exercised
here — it is a separate history-scrub increment (B-003/B-006).
"""

import pytest

from onemuseum import bcrypt, create_app
from onemuseum.config import Config
from onemuseum.users import routes as users_routes


class _TestConfig(Config):
    """Config for isolated gate testing.

    This test never touches a real database or sends mail — the user lookup is
    patched out — so dummy DB settings are fine. Providing them here means the
    test runs with no .env present (fresh clone, CI) as well as on a developer
    laptop that has one. CSRF is disabled so form POSTs need no token.
    """
    SECRET_KEY = 'test-secret-key'
    MYSQLCONN_HOST = '127.0.0.1'
    MYSQLCONN_PORT = '3306'
    MYSQLCONN_USER = 'test'
    MYSQLCONN_PASSWORD = 'test'
    MYSQLCONN_DATABASE = 'test'
    WTF_CSRF_ENABLED = False
    TESTING = True


@pytest.fixture
def app():
    """Test app built from _TestConfig. Overrides the conftest 'app' fixture
    for this module only."""
    return create_app(_TestConfig)


@pytest.fixture
def client(app):
    return app.test_client()


class _FakeUser:
    """Minimal stand-in for the User model: only what signin() touches."""

    def __init__(self, email, email_confirmed):
        self.id = 1
        self.email = email
        self.username = 'tester'
        self.email_confirmed = email_confirmed
        # a real bcrypt hash of the password 'correct-password'
        self.password = bcrypt.generate_password_hash('correct-password').decode('utf-8')

    # flask_login attributes, in case login_user is ever reached
    def get_id(self):
        return str(self.id)

    @property
    def is_active(self):
        return True

    @property
    def is_authenticated(self):
        return True

    @property
    def is_anonymous(self):
        return False


def _post_signin(client, email, password):
    return client.post(
        '/signin',
        data={'email': email, 'password': password, 'remember': False},
        follow_redirects=False,
    )


@pytest.fixture
def patch_user(monkeypatch):
    """Install a fake user for user_get_by_email; return a setter so each test
    controls the email_confirmed value."""
    holder = {}

    def _lookup(email):
        return holder.get('user')

    monkeypatch.setattr(users_routes, 'user_get_by_email', _lookup)

    def _set(email_confirmed):
        holder['user'] = _FakeUser('tester@example.com', email_confirmed)

    return _set


def test_unconfirmed_user_is_blocked(client, patch_user, monkeypatch):
    """Correct password + email_confirmed False => blocked, not logged in."""
    patch_user(email_confirmed=False)
    # create_session() would hit the DB on a real login; keep the gate isolated.
    monkeypatch.setattr(users_routes, 'create_session', lambda: None)

    resp = _post_signin(client, 'tester@example.com', 'correct-password')

    # A blocked sign-in re-renders the signin page (200), not a redirect (302).
    assert resp.status_code == 200
    assert b'confirm your email' in resp.data.lower()


def test_none_confirmed_flag_is_blocked(client, patch_user, monkeypatch):
    """email_confirmed None (never set) is falsy => also blocked."""
    patch_user(email_confirmed=None)
    monkeypatch.setattr(users_routes, 'create_session', lambda: None)

    resp = _post_signin(client, 'tester@example.com', 'correct-password')

    assert resp.status_code == 200
    assert b'confirm your email' in resp.data.lower()


def test_confirmed_user_passes_gate(client, patch_user, monkeypatch):
    """Correct password + email_confirmed True => gate lets them through.

    We assert the gate is NOT what stopped them: the 'confirm your email'
    message must be absent. (A real login redirects; create_session is stubbed.)
    """
    patch_user(email_confirmed=True)
    monkeypatch.setattr(users_routes, 'create_session', lambda: None)

    resp = _post_signin(client, 'tester@example.com', 'correct-password')

    assert b'confirm your email' not in resp.data.lower()


def test_wrong_password_never_reaches_gate(client, patch_user, monkeypatch):
    """A wrong password fails the check above the gate; the gate message must
    not appear (the user sees the generic failure instead)."""
    patch_user(email_confirmed=False)
    monkeypatch.setattr(users_routes, 'create_session', lambda: None)

    resp = _post_signin(client, 'tester@example.com', 'wrong-password')

    assert resp.status_code == 200
    assert b'confirm your email' not in resp.data.lower()
