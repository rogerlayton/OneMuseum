from flask import Blueprint, render_template

from ..dbutils import DBConnectionError
from ..diaglog import log_db_outage, log_error

errors = Blueprint('errors', __name__)


@errors.app_errorhandler(404)
def error_404(error):
    return render_template('errors/404.html'), 404


@errors.app_errorhandler(403)
def error_403(error):
    return render_template('errors/403.html'), 403


@errors.app_errorhandler(500)
def error_500(error):
    # F-015 (D-006): a 500 is always recorded for the administrator. A database
    # outage (DBConnectionError raised by dbOpen since F-013) is the no-recovery
    # case we especially care about; its message names the target and detail
    # (never the password). The original exception is on error.original_exception
    # under Flask's error handling.
    original = getattr(error, 'original_exception', None) or error
    if isinstance(original, DBConnectionError):
        log_db_outage(original)
        db_down = True
    else:
        log_error('error_500', repr(original))
        db_down = False

    # The raw error is deliberately NOT passed to the template: it can disclose
    # the connection target and internal detail to the end user. The page shows
    # a generic message; the detail lives in the administrator log only.
    return render_template('errors/500.html', db_down=db_down), 500



