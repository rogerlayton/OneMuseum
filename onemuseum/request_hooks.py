"""Per-request hooks, extracted verbatim from the former app.py.

Behaviour is preserved exactly: session inactivity timeout of 15 minutes,
and session_data logging for /d/ (DETAILS) and /c/ (CATEGORIES) routes.
"""
import datetime

import flask
import flask_login
from flask_login import current_user

from .dbutils import session_data


def register_request_hooks(app):

    # set Flask session inactivity timeout to 15 minutes
    @app.before_request
    def before_request():
        flask.session.permanent = True
        app.permanent_session_lifetime = datetime.timedelta(minutes=15)
        flask.session.modified = True
        flask.g.user = flask_login.current_user

        if current_user.is_authenticated:
            method = flask.request.method
            url = flask.request.path
            query = None
            if 'q' in flask.request.form:
                query = flask.request.form['q']
            if not url.startswith('/static/'):
                if url.startswith('/d/'):
                    method = 'DETAILS'
                    parts = url[3:].split('/')
                    etname = parts[0]
                    entityname = parts[1]
                    session_data(method, url, query, etname, entityname)
                elif url.startswith('/c/'):
                    method = 'CATEGORIES'
                    parts = url[3:].split('/')
                    etname = parts[0]
                    entityname = parts[1]
                    session_data(method, url, query, etname, entityname)
