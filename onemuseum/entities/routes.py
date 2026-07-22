from flask import Blueprint, request, render_template, session, flash, redirect
from flask_login import login_required, current_user

from ..dbutils import browserDB, dbOpen, dbClose, dbGetCategoryName, dbGetScalar
from ..sdfutils import sdf_browser

# from html_sanitizer import Sanitizer


import mysql
import markdown


entities = Blueprint('entities', __name__)


def handle_search(aSessvar, aWhereSQL, aWhereFixedSQL=''):
    """
Obtain the search value from the POST, and save in session variables.
When search value changes, tell browser to reset page to 1.
"""

        # default - do not reset page numner
    resetpage = False
    if request.method == 'POST':
            # for POST defaul = always reset page number
        resetpage = True
            # get the search argument = q
        search = request.form.get('q', '')
            # do not reset page if same search as current
        if aSessvar in session:
            if search == session.get(aSessvar):
                resetpage = False
        if search == '':
                # when empty then remove the session var, if it exists
            session.pop(aSessvar, '')
        else:
                # if non-empty, save in session e
            session[aSessvar] = search

        # always get the search from session, works for POST and GET
        # keep this for the next round of searchingsearch
    search = ''
        # prepare the search with wildcards to be used in the SQL
    searchSQL = ''

    if aSessvar in session:
        search = session.get(aSessvar)
        searchSQL = '%' + search + '%'

    whereWHERE = ' WHERE '
    whereSQL = ''
    if search != '' and aWhereSQL != '':
        whereSQL = f"{whereWHERE} ( {aWhereSQL} )"
        whereWHERE = ' AND '
        if aWhereFixedSQL != '':
            whereSQL += f"{whereWHERE} ( {aWhereFixedSQL} )"

    return (search, searchSQL, whereSQL, resetpage)


def handle_where(aSearch, aWhereSQL):
    """Create the WHERE clause for a browser and address SQL injection risk
       Keep this to extend for more advanced search strings such as
       T:war - to find the Type field with the value of "war"
    """

    whereSQL = ''
    if aSearch != '' and aWhereSQL != '':
        whereSQL = ' WHERE ' + aWhereSQL
    return whereSQL


def handle_search_where(aSessvar, aWhereSQL):
    """Combines the handle_search and handle_where together"""

    search, reset_page = handle_search(aSessvar)
    whereSQL = handle_where(search, aWhereSQL)

    return (search, whereSQL, reset_page)


@entities.route("/b/<entity>", defaults={"pagein": 1}, methods=['GET', 'POST'])
@entities.route("/b/<entity>/<pagein>", methods=['GET', 'POST'])
@login_required
def show_browser(entity, pagein):

    return gen_browser(entity, pagein)


def gen_browser(entity, pagein=1, guid=None, browser_template='genbrowserDB.html'):
    """Utility to produce a table-based or other data browser
    Can be called from many routes or within the processing of a route"""

        # get the page number and convert to integer
    try:
        page = int(pagein)
    # non-integer is an error
    except ValueError:
        flash(f"Invalid page number {pagein}", "danger")
        # return to base url without page number - will reset to 1
        return redirect(f"/b/{entity}")

    # get the browser spec for this entity in SDF form
    spec = sdf_browser(entity)
    sessvar = f"{entity}:search"
    tWhereFixed = ''
    if "where_fixed" in spec:
        tWhereFixed = spec['where_fixed']
    # get the current search arg, and create the where clause to use, and determine if page should be reset
    search, searchSQL, whereSQL, resetpage = handle_search(sessvar, spec['where'], tWhereFixed)
    # if page is to be reset, and ensure that there was a page entered (otherwise may cause infinite loop)
    # then return back to basic url without page number
    if resetpage and pagein is not None:
        return redirect(f"/b/{entity}")

    # get the list of ORDER BY clauses from the spec
    orders = spec['orders']
    # TODO : allow for user selection of the order from  form
    # currently default to selecting the first if there is one
    order = ''
    if len(orders) > 0:
        order = ' ORDER BY ' + orders[0]['order']

    # build up the SQL statements for count and browse
    fromSQL = spec.get('fromSQL', '')
    countSQL = spec.get('countSQL', None)
    if countSQL is None and fromSQL is not None:
        countSQL = "SELECT COUNT(*) FROM " + fromSQL
    countSQL += whereSQL
        # insert the FROM clause if this is not in the BROWSER command
    browserSQL = spec['browserSQL'] + " FROM " + fromSQL + whereSQL + order

    # and pass onto the browser database manager in dbutils
    return browserDB(
        countSQL, browserSQL, whereSQL,
        browser_template,
        title=spec['title'],
        object=spec['object'], entity=entity,
        page=page, per_page=spec['per_page'],
        search=search, searchSQL=searchSQL,
        fields=spec['fields'])


@entities.route("/c/<entity>/<guid>", defaults={"pagein": 1}, methods=['GET', 'POST'])
@entities.route("/c/<entity>/<guid>/<pagein>", methods=['GET', 'POST'])
@login_required
def show_categorylinks(entity, guid, pagein):

    return gen_browserCAT(entity, pagein, guid)


def gen_browserCAT(entity, pagein=1, guid=None, browser_template='genbrowserDB.html'):
    """Utility to produce a table-based or other data browser
    Can be called from many routes or within the processing of a route"""

        # get the page number and convert to integer
    try:
        page = int(pagein)
    # non-integer is an error
    except ValueError:
        flash("Invalid page number {pagein}", "danger")
        # return to base url without page number - will reset to 1
        return redirect(f"/c/{entity}/{guid}")

    # get the browser spec for this entity in SDF form
    spec = sdf_browser(entity)
    sessvar = f"{entity}:search"
    # get the current search arg, and create the where clause to use, and determine if page should be reset
    search, searchSQL, whereSQL, resetpage = handle_search(sessvar, spec['where'], spec['where_fixed'])
    # if page is to be reset, and ensure that there was a page entered (otherwise may cause infinite loop)
    # then return back to basic url without page number
    if resetpage and pagein is not None:
        return redirect(f"/c/{entity}/{guid}")

    # get the heading information about the category
    (refetID, categoryclass, categoryname) = dbGetCategoryName(guid)

    title = f'Links to {categoryname} ({categoryclass})'

    # get the list of ORDER BY clauses from the spec
    orders = spec['orders']
    # TODO : allow foro user selection of the order from  form
    # currently default to selecting the first if there is one
    order = ''
    if len(orders) > 0:
        order = ' ORDER BY ' + orders[0]['order']

    # build up the SQL statements for count and browse
    fromSQL = spec.get('fromSQL', '')
    countSQL = spec.get('countSQL', None)
    if countSQL is None and fromSQL is not None:
        countSQL = "SELECT COUNT(*) FROM " + fromSQL
    countSQL += whereSQL
        # insert the FROM clause if this is not in the BROWSER command
    browserSQL = spec['browserSQL'] + " FROM " + fromSQL + whereSQL + order

    # and pass onto the browser database manager in dbutils
    return browserDB(
        countSQL, browserSQL, whereSQL,
        browser_template,
        title=title,
        object=spec['object'], entity=entity,
        page=page, per_page=spec['per_page'],
        search=search, searchSQL=searchSQL,
        categoryid=guid,
        fields=spec['fields'])


@entities.route('/demo/ditsong', methods=['GET'])
def demo_ditsong():
    """Demo of the Ditsong Museum"""
    entity = 'museum'
    guid = 'C2904B42-841B-46FF-9EC8-AF7903D61FC8'
    userid = '24b405a3-352a-d3a7-7df2-f5ba3f3223c3'
    template = "gendetails.html"
    results = []
    data = []
    categories = []
    commondata = []
    hasContent = False
    content = "CONTENT NOT FOUND"

    DBCONN = dbOpen()
    C = DBCONN.cursor()

    # TODO this can be generalised in the future to support other applications

    if entity == "chenhall":
        template = "gendetailschenhall.html"
        id = int(guid)
        try:
            C.callproc('ChenhallDetails', args=(id, userid))
        except mysql.connector.Error as err:
            """  print(err)
            print("Error Code:", err.errno)
            print("SQLSTATE", err.sqlstate)
            print("Message", err.msg) """
            return err, 403
        for result in C.stored_results():
            columns = [col[0] for col in result.description]
            results.append([dict(zip(columns, row)) for row in result.fetchall()])
        return render_template(template, id=id, results=results)

    elif entity in ['namedplace', 'namedevent', 'subject', 'perorg', 'itemtype', 'curriculumelement']:
        template = "gendetailscategories.html"
        C.callproc('GenDetails', args=(entity, guid, userid))
        """https://stackoverflow.com/questions/29020839/mysql-fetchall-how-to-get-data-inside-a-dict-rather-than-inside-a-tuple"""
        for result in C.stored_results():
            columns = [col[0] for col in result.description]
            results.append([dict(zip(columns, row)) for row in result.fetchall()])
        data = results[0][0]

    else:  # all content entitiytypes - museums, collections, etc.
        C.callproc('GenDetails', args=(entity, guid, userid))
        """https://stackoverflow.com/questions/29020839/mysql-fetchall-how-to-get-data-inside-a-dict-rather-than-inside-a-tuple"""
        for result in C.stored_results():
            columns = [col[0] for col in result.description]
            results.append([dict(zip(columns, row)) for row in result.fetchall()])
        data = results[0][0]
        categories = results[1]
        commondata = results[2]

    dbClose(DBCONN)

    if 'Content' in data:
        hasContent = True
        content = data.get('Content')

        if content is not None:
            content = content.strip()  # strip all leading and trailing white space
            # if the first character is # then assume markdown format
            # if not then take the content as is (HTML, TEXT)
            if content.startswith('#'):
                content = markdown.markdown(
                    content,
                    extensions=[
                        'markdown.extensions.tables',
                        'markdown_katex',
                    ],
                    extension_configs={
                        'markdown_katex': {
                            'no_inline_svg': True,      # fix for WeasyPrint
                            'insert_fonts_css': True,
                        }
                    }
                )
            # sanitizer = Sanitizer()  # default configuration
            # content = sanitizer.sanitize(content)

    return render_template(template, entity=entity, guid=guid,
                           data=data, categories=categories, commondata=commondata,
                           hasContent=hasContent, content=content)


def entity_slug(table, entity, slug):
    """    """
    DBCONN = dbOpen()
    guid = dbGetScalar(f"SELECT GUID FROM {table} WHERE Slug = '{slug}'", {})
    dbClose(DBCONN)
    if guid is not None:
        return show_details(entity, guid)
    else:
        return render_template('errors/404.html')


@entities.route('/lesson/<slug>', methods=['GET'])
def lesson_slug(slug):
    """Find a lesson using a slug and pass to show_details"""
    return entity_slug('Lessons', 'lesson', slug)


@entities.route('/museum/<slug>', methods=['GET'])
def museum_slug(slug):
    """Find a museum using a slug and pass to show_details"""
    return entity_slug('Museums', 'museum', slug)


@entities.route('/collection/<slug>', methods=['GET'])
def collection_slug(slug):
    """Find a collection using a slug and pass to show_details"""
    return entity_slug('Collections', 'collection', slug)


@entities.route('/item/<slug>', methods=['GET'])
def item_slug(slug):
    """Find a item using a slug and pass to show_details"""
    return entity_slug('Items', 'item', slug)


@entities.route('/biography/<slug>', methods=['GET'])
def biography__slug(slug):
    """Find a exhibition using a slug and pass to show_details"""
    return entity_slug('Biographies', 'biography', slug)


@entities.route('/curriculumelement/<slug>', methods=['GET'])
def curriculumelement__slug(slug):
    """Find a curriculum element using a slug and pass to show_details"""
    return entity_slug('CurriculumElements', 'curriculumelement', slug)


@entities.route('/expert/<slug>', methods=['GET'])
def expert_slug(slug):
    """Find a expert using a slug and pass to show_details"""
    return entity_slug('Experts', 'expert', slug)


@entities.route('/namedplace/<slug>', methods=['GET'])
def namedplace_slug(slug):
    """Find a namedplace using a slug and pass to show_details"""
    return entity_slug('NamedPlaces', 'namedplace', slug)


@entities.route('/namedevent/<slug>', methods=['GET'])
def namedevent_slug(slug):
    """Find a named event using a slug and pass to show_details"""
    return entity_slug('NamedEvents', 'namedevent', slug)


@entities.route('/publication/<slug>', methods=['GET'])
def publication_slug(slug):
    """Find a publication using a slug and pass to show_details"""
    return entity_slug('Publications', 'publication', slug)


@entities.route('/story/<slug>', methods=['GET'])
def story_details_slug(slug):
    """Find a story using a slug and pass to show_details"""
    return entity_slug('Stories', 'story', slug)


@entities.route('/item/<slug>', methods=['GET'])
def item_details_slug(slug):
    """Find a item using a slug and pass to show_details"""
    return entity_slug('Items', 'item', slug)


@entities.route('/d/<entity>/<guid>', methods=['GET', 'POST'])
@login_required
def show_details(entity, guid):
    """The generic details form for the core content entity types. Specific variations for other entity types"""

    template = "gendetails.html"
    results = []
    data = []
    categories = []
    commondata = []
    hasContent = False
    content = ''

    DBCONN = dbOpen()
    C = DBCONN.cursor()

    # TODO this can be generalised in the future to support other applications

    if entity == "chenhall":
        template = "gendetailschenhall.html"
        id = int(guid)
        try:
            C.callproc('ChenhallDetails', args=(id, current_user.id))
        except mysql.connector.Error as err:
            """  print(err)
            print("Error Code:", err.errno)
            print("SQLSTATE", err.sqlstate)
            print("Message", err.msg) """
            return err, 403
        for result in C.stored_results():
            columns = [col[0] for col in result.description]
            results.append([dict(zip(columns, row)) for row in result.fetchall()])
        return render_template(template, id=id, results=results)

    elif entity in ['namedplace', 'namedevent', 'subject', 'perorg', 'itemtype', 'curriculumelement']:
        template = "gendetailscategories.html"
        C.callproc('GenDetails', args=(entity, guid, current_user.id))
        """https://stackoverflow.com/questions/29020839/mysql-fetchall-how-to-get-data-inside-a-dict-rather-than-inside-a-tuple"""
        for result in C.stored_results():
            columns = [col[0] for col in result.description]
            results.append([dict(zip(columns, row)) for row in result.fetchall()])
        data = results[0][0]

    else:  # all content entitiytypes - museums, collections, etc.
        try:
            C.callproc('GenDetails', args=(entity, guid, current_user.id))
        except mysql.connector.Error as err:
            """  print(err)
            print("Error Code:", err.errno)
            print("SQLSTATE", err.sqlstate)
            print("Message", err.msg) """
            return err, 403
        """https://stackoverflow.com/questions/29020839/mysql-fetchall-how-to-get-data-inside-a-dict-rather-than-inside-a-tuple"""
        for result in C.stored_results():
            columns = [col[0] for col in result.description]
            results.append([dict(zip(columns, row)) for row in result.fetchall()])
        data = results[0][0]
        categories = results[1]
        commondata = results[2]

    dbClose(DBCONN)

    if 'Content' in data:
        hasContent = True
        content = data.get('Content')

        if content is not None and content != ' ':
            content = content.strip()  # strip all leading and trailing white space
            # if the first character is # then assume markdown format
            # if not then take the content as is (HTML, TEXT)
            if content.startswith('#'):
#               content = markdown.markdown(content)
                content = markdown.markdown(
                    content,
                    extensions=[
                        'markdown.extensions.tables',
                        'markdown_katex',
                    ],
                    extension_configs={
                        'markdown_katex': {
                            'no_inline_svg': True,      # fix for WeasyPrint
                            'insert_fonts_css': True,
                        }
                    }
                )
            # sanitizer = Sanitizer()  # default configuration
            # content = sanitizer.sanitize(content)

    return render_template(template, entity=entity, guid=guid,
                           data=data, categories=categories, commondata=commondata,
                           hasContent=hasContent, content=content)
