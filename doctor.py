"""Standalone environment & database diagnostic for OneMuseum.

Run it directly. It imports nothing from the onemuseum package and does not
start the Flask application, so it is
safe to run when the app itself will not start.

    python doctor.py

Exit code 0 if every check passed, 1 if any check failed. Each check reports
independently, so one failure does not hide the checks below it.
"""
import os
import sys

# Loaded here as well as in create_app() so the doctor sees exactly the same
# configuration the app would see.
try:
    from dotenv import load_dotenv
except ImportError:  # pragma: no cover - dotenv is in requirements.txt
    load_dotenv = None

# Environment variables the application requires in order to run.
REQUIRED_VARS = (
    'SECRET_KEY',
    'MYSQLCONN_HOST',
    'MYSQLCONN_PORT',
    'MYSQLCONN_USER',
    'MYSQLCONN_PASSWORD',
    'MYSQLCONN_DATABASE',
)

# Set for mail to work, but the application will run without them.
OPTIONAL_VARS = (
    'MAIL_SERVER',
    'MAIL_USERNAME',
    'MAIL_PASSWORD',
)

# Stored procedures the application calls. Kept in step with the callproc /
# dbProcedure call sites in onemuseum/entities, /categories and /users.
REQUIRED_PROCEDURES = (
    'ChenhallDetails',
    'GenCategories',
    'GenDetails',
    'UserEntityFavourite',
)

PASS = 'PASS'
FAIL = 'FAIL'
WARN = 'WARN'


class Results:
    """Collects check outcomes and prints them as they happen."""

    def __init__(self):
        self.failed = False

    def record(self, status, label, detail=''):
        if status == FAIL:
            self.failed = True
        line = '  [{0}] {1}'.format(status, label)
        if detail:
            line += ' - {0}'.format(detail)
        print(line)

    def section(self, title):
        print('\n{0}'.format(title))
        print('-' * len(title))


def check_location():
    """Refuse to run from the wrong directory.

    This script derives the project root from its own location, so if it has
    been placed inside the onemuseum/ package (or anywhere else) it would look
    for .env in the wrong place and report a false failure. Better to say so.
    """
    root = os.path.abspath(os.path.dirname(__file__))
    markers = ('wsgi.py', 'requirements.txt')
    missing = [m for m in markers if not os.path.isfile(os.path.join(root, m))]
    if not missing:
        return root

    print('\nERROR: doctor.py is not in the project root.\n')
    print('  It is currently at:')
    print('    {0}'.format(os.path.abspath(__file__)))
    print('  but {0} was not found alongside it.\n'.format(' or '.join(missing)))
    print('  Move it next to wsgi.py and run it from there:')
    print('    mv onemuseum/doctor.py .')
    print('    python doctor.py\n')
    sys.exit(1)


def check_dotenv(results, root):
    """Report whether a .env file was found and loaded."""
    results.section('1. Configuration file')

    env_path = os.path.join(root, '.env')

    if load_dotenv is None:
        results.record(FAIL, 'python-dotenv installed',
                       'not importable; run: pip install -r requirements.txt')
        return

    if os.path.isfile(env_path):
        load_dotenv(env_path)
        results.record(PASS, '.env found', env_path)
    else:
        results.record(WARN, '.env not found',
                       'expected at {0}; falling back to the shell '
                       'environment. Copy .env.example to .env'.format(env_path))


def check_env_vars(results):
    """Report every required variable that is missing, not just the first."""
    results.section('2. Environment variables')

    missing = []
    for name in REQUIRED_VARS:
        value = os.environ.get(name)
        if value:
            # Never print secret values; confirm presence only.
            if name in ('SECRET_KEY', 'MYSQLCONN_PASSWORD'):
                results.record(PASS, name, 'set ({0} characters)'.format(len(value)))
            else:
                results.record(PASS, name, value)
        else:
            missing.append(name)
            results.record(FAIL, name, 'NOT SET')

    for name in OPTIONAL_VARS:
        value = os.environ.get(name)
        if value:
            detail = 'set' if name == 'MAIL_PASSWORD' else value
            results.record(PASS, name, detail)
        else:
            results.record(WARN, name, 'not set (mail features will not work)')

    return missing


def check_driver(results):
    """The database driver must import before any connection can be attempted."""
    results.section('3. Database driver')
    try:
        import mysql.connector  # noqa: F401
        results.record(PASS, 'mysql.connector importable')
        return True
    except ImportError as exc:
        results.record(FAIL, 'mysql.connector importable', str(exc))
        return False


def check_database(results, missing_vars):
    """Connect, then verify the database and its stored procedures."""
    results.section('4. Database connection')

    blocking = [n for n in missing_vars if n.startswith('MYSQLCONN_')]
    if blocking:
        results.record(FAIL, 'connection attempted',
                       'skipped; missing {0}'.format(', '.join(blocking)))
        return

    import mysql.connector
    from mysql.connector import errorcode

    host = os.environ.get('MYSQLCONN_HOST')
    port = os.environ.get('MYSQLCONN_PORT')
    database = os.environ.get('MYSQLCONN_DATABASE')

    conn = None
    try:
        conn = mysql.connector.connect(
            host=host,
            port=port,
            user=os.environ.get('MYSQLCONN_USER'),
            password=os.environ.get('MYSQLCONN_PASSWORD'),
            database=database,
            connection_timeout=5)
        results.record(PASS, 'connected',
                       '{0}:{1}/{2}'.format(host, port, database))
    except mysql.connector.Error as err:
        if err.errno == errorcode.ER_ACCESS_DENIED_ERROR:
            detail = ('access denied for user {0!r} - check MYSQLCONN_USER '
                      'and MYSQLCONN_PASSWORD'.format(
                          os.environ.get('MYSQLCONN_USER')))
        elif err.errno == errorcode.ER_BAD_DB_ERROR:
            detail = ('database {0!r} does not exist on {1}:{2} - check '
                      'MYSQLCONN_DATABASE'.format(database, host, port))
        else:
            detail = ('cannot reach a database at {0}:{1} - is the container '
                      'running? ({2})'.format(host, port, err))
        results.record(FAIL, 'connected', detail)
        return

    try:
        check_procedures(results, conn, database)
        check_tables(results, conn)
    finally:
        try:
            conn.close()
        except Exception:
            pass


def check_procedures(results, conn, database):
    """Every stored procedure the application calls must be present."""
    results.section('5. Stored procedures')

    cursor = conn.cursor()
    try:
        cursor.execute(
            "SELECT ROUTINE_NAME FROM information_schema.ROUTINES "
            "WHERE ROUTINE_SCHEMA = %s AND ROUTINE_TYPE = 'PROCEDURE'",
            (database,))
        present = {row[0] for row in cursor.fetchall()}
    except Exception as exc:
        results.record(FAIL, 'procedure list readable', str(exc))
        return
    finally:
        cursor.close()

    for name in REQUIRED_PROCEDURES:
        if name in present:
            results.record(PASS, name, 'present')
        else:
            results.record(FAIL, name,
                           'MISSING from database {0!r}'.format(database))


def check_tables(results, conn):
    """Row counts on core tables prove SELECT works, not merely that login did.

    These names are checked against the live schema; a missing table here means
    the database is not the one the application expects.
    """
    results.section('6. Read access')

    core_tables = ('users', 'museums', 'items', 'chenhallnomenclature')

    for table in core_tables:
        cursor = conn.cursor()
        try:
            cursor.execute('SELECT COUNT(*) FROM {0}'.format(table))
            count = cursor.fetchone()[0]
            results.record(PASS, 'SELECT on {0}'.format(table),
                           '{0} rows'.format(count))
        except Exception as exc:
            results.record(FAIL, 'SELECT on {0}'.format(table), str(exc))
        finally:
            cursor.close()


def check_katex(results):
    """Verify KaTeX maths rendering actually works.

    markdown_katex shells out to a katex binary. The binaries it bundles are
    x86_64 only (Darwin/Linux/Windows) - there is no arm64 build - so on Apple
    Silicon it raises NotImplementedError and any page containing maths returns
    a 500. Nothing else on the site is affected, which makes it easy to miss.

    The fix is a native katex on PATH:  npm install -g katex
    """
    results.section('7. Maths rendering (KaTeX)')

    try:
        import markdown
    except ImportError as exc:
        results.record(FAIL, 'markdown importable', str(exc))
        return

    try:
        import markdown_katex  # noqa: F401
    except ImportError as exc:
        results.record(FAIL, 'markdown_katex importable', str(exc))
        return

    try:
        from markdown_katex import wrapper
        cmd = wrapper.get_bin_cmd()
        results.record(PASS, 'katex binary resolved', ' '.join(cmd))
    except Exception as exc:
        results.record(FAIL, 'katex binary resolved',
                       '{0} - install a native binary with: '
                       'npm install -g katex'.format(exc))
        return

    # Resolving the command is not proof it runs; render a real expression.
    sample = '# t\n\n```math\na^2 + b^2 = c^2\n```\n'
    try:
        html = markdown.markdown(
            sample,
            extensions=['markdown.extensions.tables', 'markdown_katex'],
            extension_configs={
                'markdown_katex': {
                    'no_inline_svg': True,
                    'insert_fonts_css': True,
                }
            })
        if 'katex' in html.lower():
            results.record(PASS, 'sample expression rendered')
        else:
            results.record(FAIL, 'sample expression rendered',
                           'no KaTeX markup in output; maths will not display')
    except Exception as exc:
        results.record(FAIL, 'sample expression rendered',
                       '{0}: {1}'.format(type(exc).__name__, exc))


def main():
    print('OneMuseum diagnostic')
    print('====================')

    root = check_location()
    results = Results()

    check_dotenv(results, root)
    missing = check_env_vars(results)

    if check_driver(results):
        check_database(results, missing)
    else:
        results.section('4. Database connection')
        results.record(FAIL, 'connection attempted',
                       'skipped; database driver did not import')

    check_katex(results)

    print('')
    if results.failed:
        print('RESULT: one or more checks FAILED (see above).')
        return 1

    print('RESULT: all checks passed.')
    return 0


if __name__ == '__main__':
    sys.exit(main())
