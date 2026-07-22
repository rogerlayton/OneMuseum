# dbutils.py
#
# Roger Layton
#
# A range of functions to support common needs when
# working with MariaDB / MySQL databases
#
# IMPORTANT NOTE:
#   --- DO NOT MESS WITH THIS MODULE ---
#   This is criticial to EVERY PART Of the application and if it is wrong then
#   everything will fail and may even generate incorrect data on the database
#   ANY CHANGE TO THIS MUST BE FULLY TESTED BEFORE DEPLOYMENT
#
# V1 : 20191012
# V2 : 20201116
# - adding dbUpdate
# V3 : 2021-622
# - fixing the dbExecute for the prepared statements
# - also dbExecuteWithResults - to return a recordset
# - opening and closing CONNECTIONS on every call
#       MySQLConnection does connection pooling
#       so no benefit to keeping connections open
# - cleaning up all functions for similar structure and standards
#
# TODO:
# -- develop a full test set for this module
# -- consolidate the routines - there are overlaps
# -- determine whether to allow for separate functions 
#       which include creating connection
#    and those which do not - DBCOMM is sometimes given at the first argument
#       and sometimes not
# -- consistency in the argument and variable names
#       - build a standards document

import mysql.connector
from mysql.connector import errorcode
from flask_login import current_user
from flask import render_template, flash, session
import re
import uuid
from .config import Config
from .entities.forms import SearchForm

# using a test user until the user management finalised
# TEST_USER = 'D3C661FA-6E5D-430D-B4CD-7B7C7BFDB764'


def dbOpen():
    ''' Open the connection to the database using the environment variables set up '''
    try:
        DBCONN = mysql.connector.connect(
            host=Config.MYSQLCONN_HOST,
            port=Config.MYSQLCONN_PORT,
            user=Config.MYSQLCONN_USER,
            password=Config.MYSQLCONN_PASSWORD,
            database=Config.MYSQLCONN_DATABASE)
    except mysql.connector.Error as err:
        # TODO: fix up the error handling for when any error occur here
        if err.errno == errorcode.ER_ACCESS_DENIED_ERROR:
            print("Cannot log in with this user name / password")
        elif err.errno == errorcode.ER_BAD_DB_ERROR:
            print("Cannot find this database")
        else:
            print(err)
    finally:
        pass
    return DBCONN


def dbClose(DBCONN):
    ''' close the connection '''
    try:
        DBCONN.close()
    finally:
        pass  # if error then do nothing - may already be closed.


def dbExists(aTable, aField, aValue):
    '''Does this row exist in this table?'''
    try:
        C = None
        DBCONN = dbOpen()
        tSQL = f"SELECT COUNT(*) FROM `{aTable}` WHERE `{aField}` = %s"
        OUT = True
        C = DBCONN.cursor(prepared=True)
        C.execute(tSQL, [aValue])
        R = C.fetchone()
        row_count = R[0]
        if row_count == 0:  # text for < 1 since the result ,ay e 0 or -1
            OUT = False
        return OUT
    except mysql.connector.Error as error:
        flash(f"dbExists: Error in executing Stored Procedure : {aTable} checking {aField} = {aValue}. Error = {error}", "danger")
        return False
    finally:
        dbClose(DBCONN)


def dbGetRowFromTable(aTable, aGUID):
    '''Return a single row from a table'''
    try:
        C = None
        DBCONN = dbOpen()
        C = DBCONN.cursor()
        tSQL = f"SELECT * FROM `{aTable}` WHERE guid=%s"
        C.execute(tSQL, [aGUID])
        R = C.fetchone()
        if R is None:
            R = {"Error": "row not found"}
        return R
    except mysql.connector.Error as error:
        flash(f"dbGetRow: Error in executing Stored Procedure : {tSQL}. Error = {error}", "danger")
        return False
    finally:
        dbClose(DBCONN)


def dbGetRow(aTable, aGUID):
    '''Return a single row from a table'''
    try:
        C = None
        DBCONN = dbOpen()
        C = DBCONN.cursor()
        tSQL = f"SELECT * FROM `{aTable}` WHERE `GUID` = %s"
        C.execute(tSQL, [aGUID])
        R = C.fetchone()
        if R is None:
            R = {"Error": "row not found"}
        return R
    except mysql.connector.Error as error:
        flash(f"dbGetRow: Error in executing Stored Procedure : {aTable} / {aGUID}. Error = {error}", "danger")
        return False
    finally:
        dbClose(DBCONN)


def dbGetAll(aSQL, aArgs):
    ''' extract records from the database '''
    try:
        DBCONN = dbOpen()
        C = DBCONN.cursor()
        C.execute(aSQL, aArgs)
        OUT = []
        R = C.fetchone()
        while R is not None:
            OUT.append(R)
            R = C.fetchone()
        return OUT
    except mysql.connector.Error as error:
        flash(f"dbGetAll: Error in executing Stored Procedure : {aSQL} using arguments {aArgs}. Error = {error}", "danger")
        return False
    finally:
        dbClose(DBCONN)


def dbGetScalar(aSQL, aArgs):
    ''' Get a single scalar data from database query '''
    try:
        DBCONN = dbOpen()
        C = DBCONN.cursor()
        C.execute(aSQL, aArgs)
        OUT = None
        R = C.fetchone()
        if R is not None:
            (OUT, ) = R
        return OUT
    except mysql.connector.Error as error:
        flash(f"dbGetScalar: Error in extracing a single value from a query: {aSQL} using arguments {aArgs}. Error = {error}", "danger")
        return False
    finally:
        dbClose(DBCONN)


def dbGetDict(aSQL, aArgs):
    ''' Get data rows from database and return as dict '''
    try:
        DBCONN = dbOpen()
        C = DBCONN.cursor()
        C.execute(aSQL, aArgs)
        OUT = []
        COLS = C.column_names
        FIELDS = C.fetchone()
        while FIELDS is not None:
            ROW = dict(zip(COLS, FIELDS))
            OUT.append(ROW)
            FIELDS = C.fetchone()
        return OUT
    except mysql.connector.Error as error:
        flash(f"dbGetDict: Error in extracing rows and returning dict: {aSQL} using arguments {aArgs}. Error = {error}", "danger")
        return False
    finally:
        dbClose(DBCONN)


def dbGetCategoryName(aGUID):
    ''' Get the class and title from a Categorization entry '''
    try:
        DBCONN = dbOpen()
        C = DBCONN.cursor()
        # should only ever be 1 returned, but rather play safe
        tSQL = "SELECT RefETID, Class, ClassName, Name FROM CategoriesAll WHERE GUID = %(GUID)s"
        C.execute(tSQL, {'GUID': aGUID})
        R = C.fetchone()
        return R
    except mysql.connector.Error as error:
        flash(f"dbGetCategoryName: Error in executing Stored Procedure : {tSQL} using argument GUID={aGUID}. Error = {error}", "danger")
        return False
    finally:
        dbClose(DBCONN)


def dbExecute(aSQL, aArgs):
    ''' generin running of an SQL statement with arguments'''
    try:
        DBCONN = dbOpen()
        C = DBCONN.cursor()
        C.execute(aSQL, aArgs)
        DBCONN.commit()
        return True
    except mysql.connector.Error as error:
        DBCONN.rollback()
        flash(f"dbExecute: Error in executing SQL : {aSQL} using arguments {aArgs}. Error = {error}", "danger")
        return False
    finally:
        dbClose(DBCONN)


def dbProcedure(aProcedure, args=()):
    """Execute a stored procedure and return multiple recordsets as lists"""
    results = []
    try:
        DBCONN = dbOpen()
        C = DBCONN.cursor()
        C.callproc(aProcedure, args)
        for result in C.stored_results():
            results.append(result.fetchall())
        DBCONN.commit()
        return results
    except mysql.connector.Error as error:
        flash(f"dbProcedure: Error in executing Stored Procedure : {aProcedure} using arguments {args}. Error = {error}", "danger")
        return results
    finally:
        dbClose(DBCONN)


def dbProcedureDict(aProcedure, aArgs):
    """Execute a stored procedure and return multiple recordsets as dictionaries """
    columns = []
    results = []
    try:
        DBCONN = dbOpen()
        C = DBCONN.cursor()
        C.callproc(aProcedure, aArgs)
        for result in C.stored_results():
            columns = [col[0] for col in result.description]
            results.append([dict(zip(columns, row)) for row in result.fetchall()])
        DBCONN.commit()
        return results
    except mysql.connector.Error as error:
        flash(f"dProcedureDict: Error in executing Stored Procedure : {aProcedure} using arguments {aArgs}. Error = {error}", "danger")
        return False
    finally:
        dbClose(DBCONN)


def dbExecuteWithResults(aSQL, aArgs):
    ''' Use procedure to return a single row '''
    try:
        DBCONN = dbOpen()
        C = DBCONN.cursor(prepared=True)
        C.execute(aSQL, aArgs)
        OUT = C.fetchone()
    except mysql.connector.Error as error:
        flash(f"dbExecuteWithResults: Error in executing SQL : {aSQL} using arguments {aArgs}. Error = {error}", "danger")
        OUT = False
    finally:
        dbClose(DBCONN)
    return OUT


def dbInsert(aTable, aFieldNames, aArgs):
    ''' generic INSERT function '''
    try:
        DBCONN = dbOpen()
        C = DBCONN.cursor()
        fields = ", ".join(aFieldNames)
        values = tuple(aArgs)
        size = len(aFieldNames)
        placeholders = "%s, " * (size - 1) + "%s"
        SQL = f"INSERT INTO {aTable} ({fields}) VALUES ({placeholders}) "
        C.execute(SQL, values)
        DBCONN.commit()
        print("Record inserted successfully")
    except mysql.connector.Error as error:
        print("Failed to insert into table {}".format(error))
    finally:
        dbClose(DBCONN)


def dbUpdate(aTable, aFieldNames, aValues):
    '''
    Generic update on an existing row in a table in a database.
    Uses a list of field names and another list of values to be updated.
    One of the fields (generally the first) must be the guid PK for the table.
    '''

    try:
        DBCONN = dbOpen()
        C = DBCONN.cursor()
        field_values = dict(zip(aFieldNames, aValues))
        # check if guid field is found - not then error
        if 'guid' not in aFieldNames:
            raise Exception('primary key missing from update')
        # else get the guid value and delete from the dictionary
        else:
            guid = field_values['guid']
            del field_values['guid']

        # build up the SET clause using a comprehension
        # this only uses the %s placeholder - does not require %d for numberics

        field_values_2 = ", ".join([f + '=%s' for f in field_values])

        sql = f"UPDATE {aTable} SET {field_values_2} WHERE guid='{guid}'"
        C.execute(sql, aValues[1:])
        C.close()
        DBCONN.commit()
    except mysql.connector.Error as err:
        if err.errno == errorcode.ER_ACCESS_DENIED_ERROR:
            print("Cannot log in with this user name / password")
        elif err.errno == errorcode.ER_BAD_DB_ERROR:
            print("Cannot find this database")
        else:
            print(err)
    finally:
        dbClose(DBCONN)


def sqlvalue(v):
    """
    Prepare a data field for inclusion into an SQL UPDATE statement.
    NOTE: When using MySQL prepared statements this is not needed, since the
    CURSOR.execute(SQL, PARAMS) already puts in the PARAMS properly.
    """
    v2 = v

    # None = null value
    if v is None:
        v2 = 'NULL'

    # string = put ' around
    elif isinstance(v, str):
        v2 = "'" + v.replace("'", "\'") + "'"

    # boolean = convert True/False to 1/0
    elif isinstance(v, bool):
        if v is True:
            v2 = '1'
        else:
            v2 = '0'

    # int = convert to string
    elif isinstance(v, int):
        v2 = str(v)

    return v2


def sqltype(v):
    """
    Prepare a data field type for string formatting.
    STRING % ARGUMENTS
    In the STRING the placeholders are given using %s, %d, etc.
    NOTE: This is not needed for this proof of concept.
    """

    # default to string
    f2 = '%s'

    # string = put ' around
    if isinstance(v, str):
        f2 = "'%s'"

    # boolean = convert True/False to 1/0
    # - no specific placeholder for boolean - using %d
    elif isinstance(v, bool):
        f2 = "%d"

    # int = convert to string
    elif isinstance(v, int):
        f2 = "%d"

    return f2


def pages(curr, max):
    """Create list of pages numbers for pagination

    arg 1: current page (>0)
    arg 2: maximum page (>=curr)
    result: list of page numbers, with 0 indicating ellipsis ...
    example: 1, 0, 10, 11, 12, 0, 15
    """
    if curr < 1:
        raise ValueError("Current page must be 1 or greater")
    if curr > max:
        raise ValueError("Current page is larger than maximum page")

    # special case: if max <= 5 then always show 1..max

    if max <= 5:
        return list(range(1, max+1))

    # from this point on we know that max > 5

    # special case of curr = 1 or 2
    if curr == 1 or curr == 2:
        s = [1, 2, 3, 0, max]

    # special case of curr = max or max-1
    elif curr == max or curr == max-1:
        s = [1, 0, max-2, max-1, max]
    else:
        # 1 is always on the list
        s = [1]
        # if curr>3 then we must add 0 here for the ellipsis
        if curr > 3:
            s += [0]
        # general case: curr < max-2 can put in the final list
        if curr < max-2:
            s += [curr-1, curr, curr+1, 0, max]
        # special case: curr >= max-2
        else:
            s += list(range(curr-1, max+1))

    # special case of 1, 0, 3: fill in the 2
    if s[1] == 0 and s[2] == 3:
        s[1] = 2

    # special case of max-2, 0, max: fill in the max-1
    slen = len(s)
    if s[slen-2] == 0 and s[slen-3] == max-2:
        s[slen-2] = max-1

    return s


def browserDB(countSQL, browserSQL, whereSQL,
              template, title,
              page=1, per_page=10,
              search='', searchSQL='',
              fields=[], orders=[],
              categoryid='',
              object='', entity=''):

    form = SearchForm()

    # in case this comes in as integer
    per_page = int(per_page)

    args = {'search': searchSQL, 'userid': current_user.id}
    if categoryid is not None and categoryid != '':
        args.update({'categoryid': categoryid})

    # extract the count from the ResultsProxy object
    count = 0
    try:
        count = dbGetScalar(countSQL, {"search": '%' + search + '%'})
    except Exception as e:
        flash(f"browserDb: Error in obtaining result: {e} : {countSQL}", 'danger')

    max_page = 1 if count is None or count == 0 else (count-1) // per_page + 1
    pagelist = pages(page, max_page)

    limit = per_page
    offset = (page - 1)*per_page
    result = []
    browserSQL += f" LIMIT {limit} OFFSET {offset}"
    try:
        result = dbGetDict(browserSQL, args)
    except Exception as e:
        flash(f"Exception (Browser SQL): {e} : {browserSQL}", 'danger')

    session_data('BROWSER', '', search, entity, '')

    return render_template(
        template, title=title, data=result,
        page=page, pagelist=pagelist, maxpage=max_page,
        search=search, fields=fields, object=object,
        entity=entity, form=form)


def highlight_matches(text, query):
    """ https://gist.github.com/alexgleason/5935726472c3823d1c45 """
    def span_matches(match):
        html = '<span class="query">{0}</span>'
        return html.format(match.group(0))
    return re.sub(query, span_matches, text, flags=re.I)


def create_session():
    """Create a new Session record in the database, and link it to this user
    and store in the flask session"""

    # get new uuid and convert to CHAR(36) for the database
    my_uuid = str(uuid.uuid4())

    tSQL = 'INSERT INTO Sessions(GUID, UserID) VALUES (%s, %s)'
    tArgs = [my_uuid, current_user.id]
    dbExecute(tSQL, tArgs)
    session['sessionid'] = my_uuid

    session_data('LOGIN', '')


def session_data(type, URL,
                 data=None, ETName=None, EntityName=None,
                 RefETID=None, RefGUID=None):
    """Add a record to the sessiondata table"""

    if current_user.is_authenticated:
        session_id = session['sessionid']
        tSQL = """
INSERT INTO SessionData(SessionID, Type, URL, SearchString, ETName, EntityName, RefETID, RefGUID)
VALUES (%s, %s, %s, %s, %s, %s, %s, %s)"""
        tArgs = [session_id, type, URL, data, ETName, EntityName, RefETID, RefGUID]
        dbExecute(tSQL, tArgs)
