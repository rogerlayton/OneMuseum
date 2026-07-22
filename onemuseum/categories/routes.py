from flask import Blueprint
from flask_login import login_required, current_user

from ..dbutils import dbOpen, dbClose


categories = Blueprint('categories', __name__)


@categories.route('/c/<guid>', methods=['GET'])
@login_required
def show_category_links(guid):

    DBCONN = dbOpen()
    C = DBCONN.cursor()

    results = []

    C.callproc('GenCategories', args=(guid, current_user.id))
    for result in C.stored_results():
        columns = [col[0] for col in result.description]
        results.append([dict(zip(columns, row)) for row in result.fetchall()])

    data = results[0][0]

    dbClose(DBCONN)

    return f"TODO: Show all content which links to category {guid}: {data} "
