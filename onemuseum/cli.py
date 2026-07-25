"""Administrative CLI commands for OneMuseum.

These run from a terminal only — they are not routes, not linked from any
page, and require shell access to the server. That is deliberate: it keeps
administrative facilities isolated from the public user interface, which is
the stated design goal.

Registered onto the app in create_app() via register_cli(app). Run them with:

    flask --app wsgi create-user
    flask --app wsgi list-users

The create-user command inserts through the SAME logic the web signup uses
(bcrypt hashing + dbInsert('Users', ...) + the schema's GUID trigger), so a
user created here is indistinguishable from one created through the form —
except that it skips the email-confirmation step and marks the account
confirmed, so it can sign in immediately for testing. Pass --unconfirmed to
reproduce the real signup state instead.
"""

from datetime import datetime

import click

# Note: bcrypt and the dbutils helpers are imported *inside* register_cli /
# the command bodies, not at module top level. Importing them at import time
# creates a circular import (onemuseum/__init__.py imports this module while
# it is still defining bcrypt).


def register_cli(app):
    """Attach the admin CLI commands directly to the Flask app.

    Registering on app.cli (not via a blueprint) keeps the commands at the top
    level -- `flask create-user`, not `flask admin_cli create-user`.
    """
    from . import bcrypt
    from .dbutils import dbExists, dbInsert, dbGetDict, dbUpdate

    @app.cli.command('create-user')
    @click.option('--email', prompt=True, help='Email address (login identity).')
    @click.option('--username', prompt=True, help='Display username.')
    @click.option('--password', default=None,
                  help='Password. Omit to be prompted (recommended).')
    @click.option('--display-name', default=None,
                  help='Full display name (DisplayName column). Optional.')
    @click.option('--unconfirmed', is_flag=True, default=False,
                  help='Leave email unconfirmed, as the real signup does. '
                       'Default is confirmed so the user can sign in at once.')
    def create_user(email, username, password, display_name, unconfirmed):
        """Create a user directly, for development and testing.

        Mirrors onemuseum/users/routes.py::signup() minus the web form, CSRF
        token and confirmation email.
        """
        # Same duplicate checks the SignUpForm validators enforce.
        if dbExists('Users', 'email', email):
            raise click.ClickException(
                f"A user with email {email!r} already exists.")
        if dbExists('Users', 'username', username):
            raise click.ClickException(
                f"A user with username {username!r} already exists.")

        # Prompt for the password HERE (not via password_option) so the prompt
        # can name the account and flag it as a TEST credential -- the default
        # click prompt just says "Password:" with no context, which led to a
        # real credential being entered by mistake.
        if not password:
            click.echo(f"Setting a TEST password for {username!r} <{email}>.")
            click.echo("Use a throwaway dev password, NOT a real one.")
            password = click.prompt('  Test password', hide_input=True,
                                     confirmation_prompt=True)

        # Identical hashing to signup(): bcrypt, decoded to str for storage.
        hashed_password = bcrypt.generate_password_hash(password).decode('utf-8')

        confirmed = not unconfirmed
        now = datetime.now()

        # Field list mirrors signup() exactly. GUID is deliberately NOT supplied
        # -- the Users table trigger generates it, which is why the web signup
        # omits it too. Adding one here would diverge from real behaviour.
        tFields = [
            'UserName', 'Email', 'Password', 'registered_on',
            'email_confirmation_sent_on', 'email_confirmed', 'email_confirmed_on']
        tValues = [
            username, email, hashed_password, now,
            now, confirmed, now if confirmed else None]

        # DisplayName is optional; only set it when provided so the command's
        # default behaviour is unchanged.
        if display_name:
            tFields.append('DisplayName')
            tValues.append(display_name)

        dbInsert('Users', tFields, tValues)

        click.echo(f"Created user {username!r} <{email}> "
                   f"({'confirmed' if confirmed else 'UNCONFIRMED'}).")
        if not confirmed:
            click.echo("Note: unconfirmed users may be unable to sign in until "
                       "the email is confirmed.")

    @app.cli.command('reset-password')
    @click.option('--email', prompt=True, help='Email of the account to reset.')
    @click.option('--password', default=None,
                  help='New password. Omit to be prompted (recommended).')
    def reset_password(email, password):
        """Reset a user's password (development and testing).

        Looks the account up by email and rehashes a new password with the
        same bcrypt path the app uses, so the reset login behaves identically
        to a real one.
        """
        rows = dbGetDict(
            "SELECT GUID, UserName FROM Users WHERE Email = %s", (email,))
        if not rows:
            raise click.ClickException(f"No user with email {email!r}.")
        guid = rows[0].get('GUID')
        username = rows[0].get('UserName')

        if not password:
            click.echo(f"Setting a TEST password for {username!r} <{email}>.")
            click.echo("Use a throwaway dev password, NOT a real one.")
            password = click.prompt('  New test password', hide_input=True,
                                     confirmation_prompt=True)

        hashed_password = bcrypt.generate_password_hash(password).decode('utf-8')
        # dbUpdate requires the guid PK as the first field.
        dbUpdate('Users', ['guid', 'Password'], [guid, hashed_password])
        click.echo(f"Password reset for {username!r} <{email}>.")

    @app.cli.command('check-login')
    @click.option('--email', prompt=True, help='Email of the account to check.')
    @click.option('--password', default=None,
                  help='Password to test. Omit to be prompted (recommended).')
    def check_login(email, password):
        """Verify a login WITHOUT starting a session, the way the app does.

        Runs the same check as signin(): look up the user by email, then
        bcrypt.check_password_hash(stored_hash, password). Reports the TRUE
        result. It also warns if the account is one the live app would
        force-login regardless of password (the B-003 bypass), and whether the
        account is unconfirmed -- so the report reflects reality, not the app's
        buggy behaviour.
        """
        if not password:
            password = click.prompt('Password to test', hide_input=True)

        rows = dbGetDict(
            "SELECT GUID, UserName, Password, email_confirmed "
            "FROM Users WHERE Email = %s", (email,))
        if not rows:
            click.echo(f"  NO SUCH USER: {email!r}")
            click.echo("  (Note: the live signin() would raise AttributeError "
                       "here, since it checks user.email on a missing user.)")
            raise click.exceptions.Exit(1)

        row = rows[0]
        stored = row.get('Password') or ''
        username = row.get('UserName')
        confirmed = bool(row.get('email_confirmed'))

        # The genuine check -- identical to signin().
        try:
            ok = bcrypt.check_password_hash(stored, password)
        except ValueError:
            # stored value isn't a valid bcrypt hash (e.g. the plaintext
            # 'password' rows found in the legacy data).
            ok = False
            click.echo("  WARNING: stored password is not a valid bcrypt hash.")

        click.echo(f"  user:      {username!r} <{email}>")
        click.echo(f"  password:  {'CORRECT' if ok else 'WRONG'}")
        click.echo(f"  confirmed: {'yes' if confirmed else 'NO'}")
        if not confirmed:
            click.echo("             (unconfirmed -- but note the live app does "
                       "NOT currently block unconfirmed logins).")

        if email in ('roger107@rl.co.za', 'linkmunirih@gmail.com'):
            click.echo("  BYPASS:    this email is force-logged-in by the live "
                       "app REGARDLESS of password (B-003).")

        if not ok:
            raise click.exceptions.Exit(1)

    @app.cli.command('list-users')
    def list_users():
        """List users (username, email, confirmed) for a quick sanity check."""
        rows = dbGetDict(
            "SELECT username, email, email_confirmed FROM Users "
            "ORDER BY registered_on DESC", ())
        if not rows:
            click.echo("No users found.")
            return
        for r in rows:
            flag = 'confirmed' if r.get('email_confirmed') else 'unconfirmed'
            click.echo(f"  {r.get('username'):<20} {r.get('email'):<32} {flag}")
