from flask import render_template, Blueprint
from flask_login import login_required
from ..config import Config
from ..cache import Cache

admin = Blueprint('admin', __name__)


@admin.route("/a/cache", methods=['GET', 'POST'])
@login_required
def cachebrowser():
    result = Cache.get_all()
    fields = [
        {"name": "Key", "cols": 4},
        {"name": "Content", "cols": 7},
    ]

    return render_template('genbrower.html',
                           title='Cache Inspector',
                           data=result,
                           fields=fields,
                           object='cache',
                           entity='cache',
                           no_stars=True)


@admin.route("/a/users")
@login_required
def users():
    return render_template('users.html')


@admin.route("/check_installation")
def check_installation():
    """ COnduct a full set of checks that the installation is correct and functioning properly.
    And report this into a basic table, highlighting any errors.
    Each row has the check, the result, and notes to assist.
    """

    data = []

    # DATABASE CHECKS

    data.append(['DATABASE', '', ''])

    data.append(['host', Config.MYSQLCONN_HOST, ''])
    data.append(['post', Config.MYSQLCONN_PORT, ''])
    data.append(['database', Config.MYSQLCONN_DATABASE, ''])
    data.append(['user', Config.MYSQLCONN_USER, ''])

    """ DBCONN = dbOpen()
    data.append(['DBCONN', DBCONN, ''])

    dbClose(DBCONN) """

    return render_template('check_installation.html', data=data)
