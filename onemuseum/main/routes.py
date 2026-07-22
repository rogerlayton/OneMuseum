from flask import render_template, request, Blueprint, redirect
from flask_login import login_required
# from ..config import Config
from ..sdfutils import sdf_menu

main = Blueprint('main', __name__)


@main.route("/")
@main.route("/starter")
def starter():
    return render_template('starter.html')


@main.route("/home")
@login_required
def home():
    """Show the home page with the options for opening up the other functions"""

    menu_spec = sdf_menu("home", True)
    title = menu_spec.get('title', 'NO TITLE GIVEN')
    cards = menu_spec.get('items', [])

    return render_template('home.html', title=title, cards=cards)


@main.route("/about")
def about():
    return redirect('/s/version')


@main.route("/notyet")
def notyet():
    """Provide a 'Not Yet Implemented' page"""

    title = request.args.get('title', 'NOT SPECIFIED')
    content = request.args.get('content', 'NO CONTENT')
    return render_template(
        'notyet.html',
        title=title,
        content=content)


''' MUST BE REWRITTEN TO REMOVE SQL Alchemy
@main.route("/ta/<source>/<query>")
@login_required
def typeahead(source, query):
    """Typeahead support for dropdown lists"""

    # conn = engine.connect()

    dropdownSQL = ''
    if source == 'ch':
        dropdownSQL = f'SELECT Name FROM ChenhallNomenclature WHERE Name LIKE "%{query}%" LIMIT 20'

    # s = text(dropdownSQL)
    #result = conn.execute(s)

    return jsonify(result.cursor._rows) '''
