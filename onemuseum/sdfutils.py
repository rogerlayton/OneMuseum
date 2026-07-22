import os
from .cache import Cache


"""
SDFUTILS.PY
Process SDF Files

sdf_loader : read and place into a Python List

"""

_specs_root = '/static/specs/'

# Directory of this package (onemuseum/). Spec files live under
# onemuseum/static/specs/. Anchoring to the package location (not the process
# working directory) makes SDF loading independent of where the app is
# launched from. See D-002.
_PACKAGE_DIR = os.path.dirname(os.path.abspath(__file__))


def sdf_schema_loader(aFile):
    """ sdf_schema_load(aFile): load a schema file as an SDF file and store in cache """


def sdf_validate(aCommands, aSchema):
    """ sdf:validate: validate a set of Commands from an SDF filed against a schema """
    """ currently just accept that this works - later will read the schema file and validate against it """
    return True


def sdf_loader(aFile):
    """ sdf_loader: load an SDF file from storage and split into commands """

    # Resolve spec files relative to this package (see D-002), not os.getcwd().
    # aFile arrives as e.g. '/static/specs/browsers/x.sdf'; the leading slash
    # is stripped so it joins cleanly under the package directory.
    dirpath = _PACKAGE_DIR

    # build up the file path
    tFile = os.path.join(dirpath, aFile.lstrip('/'))

    # open up the file in readonly mode
    # open up the file in readonly mode
    try:
        fi = open(tFile, "r")
    except Exception:
        raise

    # read the first line

    i = 0  # current input line number
    j = 0  # command number
    k = 0  # starting line number
    commands = []

    first = True
    command = ''
    body = ''
    nl = ''
    schema = ''

    lines = fi.readlines()

    # cycle through each of the lines found on the input file
    for line in lines:

        # increment the line number
        i = i+1

        # remove the end of line character, which is included when using readline
        # this is identified as a Python "feature"
        if line[-1:] == "\n":
            line = line[:-1]

        # handle blank lines - which will be completeld ignored
        # also comment lines starting with # also ignored
        if len(line) == 0 or line[0] == '#':
            continue

        # handle the system commands, which are handled here rather than in the entity functions
        # which call this (such as sdf_browser below)

        if line[0] == '!':
            parts = line.split(' ', 1)

            if parts[0] == '!SCHEMA':
                schema = parts[1]
                continue

            # check whether to insert a newline between multi-line commands bodies
            # also can reset this back to empty string (default)
            elif parts[0] == "!ML":
                if parts[1] == 'NEWLINE':
                    # TODO causes problems in SQL - inserts raw \n and not newline
                    # nl = '\n'
                    continue
                elif parts[1] == "NONE":
                    nl = ''
                    continue

        # if this is a blank line or starts with a space then continue data from previous line
        if line[0] == ' ':
            body += nl + line  # includes an initial space, since this was already found or added (if empty)
            continue

        # all lines from this point onwards will have a non-empty first char
        # so process the previous line

        if first:
            first = False
        else:
            j = j + 1  # increment the command number
            commands.append(tuple((k, i, j, command, body)))
            command = ''
            body = ''

        # split off the command (there is ALWAYS an initial command on every line)
        # and keep the rest as the body, this is why we only do ONE split

        k = i  # save starting line for new comand
        parts = line.split(' ', 1)

        if len(parts) > 0:
            command = parts[0]
        if len(parts) > 1:
            body = parts[1]

    # handle the final command, if there is at least one line
    if i > 0:
        j = j + 1  # increment the command number
        # append tuple to list to make it easier to extract individual fields
        commands.append(tuple((k, i, j, command, body)))

    fi.close()
    # ingestmsg ("INFO", i, j, f"COMMAND={command}, BODY={body}")

    if not sdf_validate(commands, schema):
        return []

    return commands


def sdf_browser(aBrowser, aDelete=False):
    """
    sdf_browser: Read in an SDF file and process as a BROWSER
    """

    # create the browser code for the cache

    browser_code = "BROWSER:" + aBrowser

    # if this is a delete request, then we delete before loading
    if aDelete:
        Cache.remove(browser_code)

    # if this code is already in cache then replace it
    browser_spec = Cache.get(browser_code, None)
    # if browser_spec is not None:
    #    return browser_spec

    browser_spec = {}
    DELIMITER = ","
    commands = sdf_loader(f'{_specs_root}browsers/{aBrowser}.sdf')
    # args = []  # arguments for the SQL to filter it
    fields = []  # fields to display
    orders = []  # ORDER BY clauses for user to select from (currently only select the first)

    # TODO this may not work if there is nothing in commands
    for linefrom, lineto, commandnum, command, data in commands:
        if command[0] == "!":  # system command
            if command[1] == "D":  # delimiter
                if data == '':
                    DELIMITER = ','
                else:
                    DELIMITER = data.strip()
        if command == "OBJECT":
            browser_spec.update(object=data)
        elif command == "ENTITY":
            browser_spec.update(entity=data)
        elif command == "TITLE":
            browser_spec.update(title=data)
        elif command == "PERPAGE":
            browser_spec.update(per_page=data)
        elif command == "FROM":
            browser_spec.update(fromSQL=data)
        elif command == "WHERE":
            browser_spec.update(where=data)
        elif command == "WHEREFIXED":
            browser_spec.update(where_fixed=data)
        elif command == "COUNT":
            browser_spec.update(countSQL=data)
        elif command == "BROWSER":
            browser_spec.update(browserSQL=data)

            # not using the ARGS at present, was considering these to include into the
            # WHERE statement but rather extended WHERE with the additional SP parameters)
        # elif command == "KEY":
        #     key = data.split(DELIMITER)
        #     # TODO what if there are not 2 fields in elements
        #     datatype = key.get(2, "GUID")
        #     required = key.get(3, True)
        #     key.append({"field_name": key[0], "field_sql": key[1], "datatype": datatype, "required": required})

        elif command == "ORDER":
            order = data.split(DELIMITER, 1)
            # TODO what if there are not 2 fields in elements
            orders.append({"name": order[0], "order": order[1]})

        elif command == "FIELD":
            elements = data.split(DELIMITER)
            # TODO what if there are not 2 fields in elements
            fields.append({"name": elements[0], "cols": int(elements[1])})

    browser_spec.update(fields=fields, orders=orders)
    Cache.add(browser_code, browser_spec)

    return browser_spec


def sdf_details(aEntity, aDelete=False):
    """
    sdf_details: Read in an SDF file and process as a DETAILS PAGE
    """

    # create the DETAILS code for the cache

    details_code = "DETAILS:" + aEntity

    # if this is a delete request, then we delete the cache before loading
    if aDelete:
        Cache.remove(details_code)

    # if this code is already in cache then replace it
    details_spec = Cache.get(details_code, None)
    # if details_spec is not None:
    #    return details_spec

    details_spec = {}
    DELIMITER = ","
    commands = sdf_loader(f'{_specs_root}details/{aEntity}.sdf')
    fields = []  # fields to display

    # TODO this may not work if there is nothing in commands
    for linefrom, lineto, commandnum, command, data in commands:
        if command[0] == "!":  # system command
            if command[1] == "D":  # delimiter
                if data == '':
                    DELIMITER = ','
                else:
                    DELIMITER = data.strip()
        if command == "OBJECT":
            details_spec.update(object=data)
        elif command == "SQL":
            details_spec.update(SQL=data)
        elif command == "FIELD":
            elements = data.split(DELIMITER)
            # TODO what if there are not 2 fields in elements
            fields.append({"name": elements[0]})

    details_spec.update(fields=fields)
    Cache.add(details_code, details_spec)

    return details_spec


def sdf_menu(aMenu, aDelete=False):
    """ sdf_menu: Read in an SDF file and process as a MENU """

    # create the browser code for the cache

    menu_code = "MENU:" + aMenu

    # if this is a delete request, then we delete before loading
    if aDelete:
        Cache.remove(menu_code)

    # if this code is already in cache then replace it
    menu_spec = Cache.get(menu_code, None)
    # if menu_spec is not None:
    #    return menu_spec

    # need to create the menu from the SDF file
    menu_spec = {}
    DELIMITER = ","
    commands = sdf_loader(f'{_specs_root}menus/{aMenu}.sdf')
    items = []

    # TODO this may not work if there is nothing in commands
    for linefrom, lineto, commandnum, command, data in commands:
        if command[0] == "!":  # system command
            if command[1] == "D":  # delimiter
                DELIMITER = data.strip()
        elif command == "TITLE":
            menu_spec.update(title=data)
        elif command == "GROUP":
            elements = data.split(DELIMITER)
            group = {
                "type": "GROUP",
                "name": elements[0].strip(),
                "description": elements[1].strip()
            }
            items.append(group)
        elif command == "ENDGROUP":
            items.append({
                "type": "ENDGROUP"})
        elif command == "ITEM":
            elements = data.split(DELIMITER)
            if len(elements) >= 5:
                # must be 5 elements else ignored
                item = {
                    "type": "ITEM",
                    "title": elements[0].strip(),
                    "text": elements[1].strip(),
                    "folder": elements[2].strip(),
                    "img": elements[3].strip(),
                    "target": elements[4].strip(),
                }
                if len(elements) == 6:
                    item.update({'targetarg1': elements[5].strip()})
                if len(elements) < 5 or len(elements) > 6:
                    raise ValueError(f'The line {data} on line {linefrom} requires 5 or 6 arguments')
                items.append(item)

    menu_spec.update(items=items)
    Cache.add(menu_code, menu_spec)

    return menu_spec


def sdf_support(aPage, aDelete=False):
    """ sdf_support: Read in the SDF file and convert to HTML"""

    support_code = "SUPPORT:" + aPage

    # if this is a delete request, then we delete before loading
    if aDelete:
        Cache.remove(support_code)

    # if this code is already in cache then replace it
    support_spec = Cache.get(support_code, None)
    # if support_spec is not None:
    #    return support_spec

    # need to create the page from the SDF file
    support_spec = {}
    commands = sdf_loader(f'{_specs_root}support/{aPage}.sdf')
    lines = []

    for linefrom, lineto, commandnum, command, data in commands:
        if command == "TITLE":
            support_spec.update(title=data)
        else:
            lines.add(command)
    support_spec.update(lines=lines)
    Cache.add(support_code, support_spec)

    return support_spec
