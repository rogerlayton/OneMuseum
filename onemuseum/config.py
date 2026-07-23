import os

from dotenv import load_dotenv

# Load .env from the project root before any value is read, so configuration
# is identical however the app is launched (flask run, gunicorn, VS Code).
# Values already present in the real environment take precedence.
BASE_DIR = os.path.abspath(os.path.dirname(__file__))
PROJECT_ROOT = os.path.abspath(os.path.join(BASE_DIR, os.pardir))
load_dotenv(os.path.join(PROJECT_ROOT, '.env'))


class Config:
    SECRET_KEY = os.environ.get('SECRET_KEY')
    MAIL_SERVER = os.environ.get('MAIL_SERVER')
    MAIL_PORT = 587
    MAIL_USE_TLS = True
    MAIL_USERNAME = os.environ.get('MAIL_USERNAME')
    MAIL_PASSWORD = os.environ.get('MAIL_PASSWORD')
    BASE_DIR = BASE_DIR
    MYSQLCONN_USER = os.environ.get('MYSQLCONN_USER')
    MYSQLCONN_PASSWORD = os.environ.get('MYSQLCONN_PASSWORD')
    MYSQLCONN_HOST = os.environ.get('MYSQLCONN_HOST')
    MYSQLCONN_PORT = os.environ.get('MYSQLCONN_PORT')
    MYSQLCONN_DATABASE = os.environ.get('MYSQLCONN_DATABASE')


# Required to run. Mail settings are deliberately excluded: the app runs
# without them, only mail features are unavailable.
REQUIRED_CONFIG = (
    'SECRET_KEY',
    'MYSQLCONN_HOST',
    'MYSQLCONN_PORT',
    'MYSQLCONN_USER',
    'MYSQLCONN_PASSWORD',
    'MYSQLCONN_DATABASE',
)


class ConfigError(RuntimeError):
    """Raised at startup when required configuration is missing."""


def validate_config(config):
    """Raise ConfigError naming every missing required setting.

    Called from create_app() so a misconfigured app fails once, at startup,
    with an actionable message — rather than raising an identical unreadable
    error on every request afterwards.
    """
    missing = [name for name in REQUIRED_CONFIG if not config.get(name)]
    if not missing:
        return

    env_path = os.path.join(PROJECT_ROOT, '.env')
    lines = [
        '',
        'OneMuseum cannot start: required configuration is missing.',
        '',
        'Missing setting{0}:'.format('' if len(missing) == 1 else 's'),
    ]
    lines += ['  - {0}'.format(name) for name in missing]
    lines += ['', 'To fix this:']

    if os.path.isfile(env_path):
        lines += [
            '  Your .env file exists at:',
            '    {0}'.format(env_path),
            '  but does not set the value{0} above. Add {1}, then restart.'.format(
                '' if len(missing) == 1 else 's',
                'it' if len(missing) == 1 else 'them'),
        ]
    else:
        lines += [
            '  No .env file was found at:',
            '    {0}'.format(env_path),
            '  Create one from the template, fill in the values, then restart:',
            '    cp .env.example .env',
        ]

    lines += [
        '',
        'To check your whole setup, including the database, run:',
        '    python doctor.py',
        '',
    ]
    raise ConfigError('\n'.join(lines))
