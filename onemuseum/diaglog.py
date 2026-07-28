# diaglog.py
#
# F-015 (D-006): administrator diagnostic logging.
#
# Layer 2 of the D-005 remediation plan. A single application logger writing
# one line per event, so failures are diagnosable without code spelunking.
#
# Design (see D-006):
#   * ERRORS are ALWAYS logged, regardless of the DIAG_LOGGING flag. The event
#     this exists for -- the database being unreachable -- is a no-recovery
#     condition the administrator must know about; a flag being off must never
#     hide it.
#   * DIAG_LOGGING gates only the noisier per-query DIAGNOSTIC detail (SQL +
#     params), which is switched on during a deliberate debugging session.
#   * The destination is a STREAM chosen by configuration, so the SAME code
#     logs to a file on a developer laptop and to stdout/stderr inside a
#     container (where the platform -- Docker / Azure / CloudWatch -- captures
#     and aggregates the stream). This is the container-native convention the
#     image already follows (PYTHONUNBUFFERED, gunicorn --access-logfile -),
#     and it means logging carries NO network dependency: it works precisely
#     when the database (or any other service) is down.
#
# One line per message. Pipe-delimited fields:
#     ISO-8601 timestamp | LEVEL | route | message
# `route` is the current request path when there is one, else '-' (CLI,
# startup, background). The message never contains a newline (see _oneline).

import logging
import os
import sys

LOGGER_NAME = 'onemuseum'

# A private sentinel so configure_logging() is idempotent -- calling it twice
# (e.g. in tests, or if create_app runs more than once) does not stack
# duplicate handlers and multiply every line.
_CONFIGURED_FLAG = '_onemuseum_configured'


class _RouteFormatter(logging.Formatter):
    '''Formatter that adds the current Flask request path as `route`.

    Import of flask.request is done lazily inside format() so this module has
    no import-time dependency on an application context, and so a logging call
    made outside any request (CLI, startup) degrades to '-' rather than
    raising.
    '''

    def format(self, record):
        if not hasattr(record, 'route'):
            record.route = self._current_route()
        return super().format(record)

    @staticmethod
    def _current_route():
        try:
            from flask import request, has_request_context
            if has_request_context():
                return request.path
        except Exception:
            pass
        return '-'


def _oneline(text):
    '''Collapse a message to a single physical line.

    The log contract is one line per event; a stored-procedure error or a
    chained driver message can contain newlines, which would break grep, log
    shippers, and the eventual admin view. Newlines and carriage returns
    become spaces.
    '''
    return ' '.join(str(text).replace('\r', ' ').replace('\n', ' ').split())


def _resolve_stream(config):
    '''Return an open stream for the log, honouring configuration.

    LOG_FILE set  -> append to that file (developer laptop; the directory is
                     created if missing).
    LOG_FILE unset-> stderr (container / production; the platform captures it).

    A file that cannot be opened (permission, bad path) falls back to stderr
    with a single warning rather than taking the application down: logging must
    never be the thing that crashes the app.
    '''
    log_file = config.get('LOG_FILE')
    if not log_file:
        return sys.stderr, 'stderr'

    try:
        directory = os.path.dirname(os.path.abspath(log_file))
        if directory and not os.path.isdir(directory):
            os.makedirs(directory, exist_ok=True)
        stream = open(log_file, 'a', encoding='utf-8')
        return stream, log_file
    except OSError as err:
        sys.stderr.write(
            f'onemuseum: cannot open LOG_FILE {log_file!r} ({err}); '
            f'logging to stderr instead.\n')
        return sys.stderr, 'stderr'


def configure_logging(config):
    '''Attach the single 'onemuseum' logger, per D-006.

    `config` is a mapping (app.config, or any dict) providing DIAG_LOGGING and
    optionally LOG_FILE. Taking the config rather than the whole app keeps this
    decoupled from Flask and directly testable. Called once from create_app().
    Idempotent. After this, any module can do
    `logging.getLogger('onemuseum')` and the three helpers below use it.
    '''
    logger = logging.getLogger(LOGGER_NAME)

    if getattr(logger, _CONFIGURED_FLAG, False):
        return logger

    # DIAG_LOGGING truthy -> DEBUG (diagnostic lines pass); else INFO (errors
    # and above only). Errors are logged either way because they are >= INFO.
    diag_on = bool(config.get('DIAG_LOGGING'))
    logger.setLevel(logging.DEBUG if diag_on else logging.INFO)

    stream, destination = _resolve_stream(config)
    handler = logging.StreamHandler(stream)
    handler.setFormatter(_RouteFormatter(
        fmt='%(asctime)s | %(levelname)s | %(route)s | %(message)s',
        datefmt='%Y-%m-%dT%H:%M:%S%z',
    ))
    logger.addHandler(handler)

    # Do not also propagate to the root logger: that would double-print under
    # gunicorn, which configures root itself.
    logger.propagate = False

    setattr(logger, _CONFIGURED_FLAG, True)
    logger.info(_oneline(
        f'diagnostic logging started (DIAG_LOGGING={diag_on}, '
        f'destination={destination})'))
    return logger


def get_logger():
    '''The application logger. Safe to call before configure_logging(): a bare
    getLogger with no handler simply produces no output until configured.'''
    return logging.getLogger(LOGGER_NAME)


# --- The three helpers the data layer calls -------------------------------

def log_error(where, message):
    '''Always-logged error line. Use for conditions the administrator must see
    regardless of the DIAG_LOGGING flag -- database unreachable, a query or
    stored procedure failing.'''
    get_logger().error(_oneline(f'{where}: {message}'))


def log_db_outage(exc):
    '''Convenience for the DBConnectionError path. The exception message
    already names the target and detail (and never the password -- F-013).'''
    get_logger().error(_oneline(f'DB-OUTAGE: {exc}'))


def log_diag(where, message):
    '''Verbose diagnostic line. Emitted ONLY when DIAG_LOGGING is on (the
    logger is at DEBUG). Use for per-query SQL + params during a debugging
    session -- never for anything the administrator must not miss.'''
    get_logger().debug(_oneline(f'{where}: {message}'))
