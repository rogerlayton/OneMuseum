from flask import render_template, Blueprint, render_template_string, jsonify, flash
# from flask import url_for, flash, redirect, abort
# from flask_mail import Message

from ..dbutils import dbGetCategoryName, dbExecute, dbExecuteWithResults, dbGetDict
import markdown
import markdown.extensions.fenced_code
from markdown.extensions.fenced_code import FencedCodeExtension

import os

pocs = Blueprint('pocs', __name__)


@pocs.route("/pocs", methods=['GET'])
def poc_home():
    return render_template('poc-00.html', title='All Proof of Concepts')


@pocs.route("/pocs/1", methods=['GET'])
def poc01():

    (RefETID, Class, Name) = dbGetCategoryName('BD9E5F86-9491-451F-871F-845B56486ED0')

    return f"""
    <h2>Proof of Concept 1 : Get CategoryDetails</h2>
    <p>RefETID = {RefETID}</p>
    <p>Class = {Class}</p>
    <p>Name = {Name}</p>
    """


@pocs.route("/pocs/2", methods=['GET'])
def poc02():

    tSQL = 'INSERT INTO Sessions(UserID) VALUES (%(UserID)s)'
    tArgs = {'UserID': 'D3C661FA-6E5D-430D-B4CD-7B7C7BFDB764'}

    ret = dbExecute(tSQL, tArgs)
    return f"""
    <h2>Proof of Concept 2 : DB Execute/h2>
    <p>tSQL = {tSQL}</p>
    <p>Args = {tArgs}</p>
    <p>Result = {ret}</p>
    """


@pocs.route("/pocs/3", methods=['GET'])
def poc03():

    md_file = "markdownPOC.md"
    folder = os.path.dirname(os.path.realpath(__file__))
    md_path = os.path.join(folder, md_file)

    with open(md_path, "r", encoding="utf-8") as input_file:
        md_text = input_file.read()
    html = markdown.markdown(md_text, extensions=['fenced_code', FencedCodeExtension()])
    # html2 = f"""
# <link rel="stylesheet" href="../static/splendor.css">
# {html}
#    """
    return html


@pocs.route("/pocs/4", methods=['GET'])
def poc04():
    html = '''
<html>
<head>
    <link rel="stylesheet" href="../static/main.css">
    <link rel="stylesheet" href="../static/nucleoicons/css/style.css">
</head>
<body>
    <div class='table table-responsive'>
    <div class='row'>
        <div class='col-md-4'>
            <p class="icon icon-warning">
                <i class='om-icons icon-folder-13' style='color:red;'></i>
            </p>
        </div>
        <div class='col-md-4'>
            <p class="icon icon-warning">
                <i class='om-icons icon-log-in-1'></i>
            </p>
        </div>
    </div>
    </div>
</body>
</html>
    '''
    return html


@pocs.route("/pocs/5", methods=['GET'])
def poc05():
    '''https://stackoverflow.com/questions/34704997/jquery-autocomplete-in-flask'''

    html = '''
<html>
<head>
    <link rel="stylesheet" href="../static/main.css">
    <link rel="stylesheet" href="../static/nucleoicons/css/style.css">
</head>
<body>
    <h2>Showing image A22B708B-E8D7-0CA0-2ACE-5D52B3F3F615</h2>
    <hr>
    <img src='{{ url_for(images.get_image, imageGUID="A22B708B-E8D7-0CA0-2ACE-5D52B3F3F615"}}' />
    <hr>
</body>
</html>
    '''
    return render_template_string(html)


@pocs.route("/pocs/6", methods=['GET'])
def poc06():
    '''https://stackoverflow.com/questions/34704997/jquery-autocomplete-in-flask'''

    html = '''
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>jQuery UI Autocomplete - Remote datasource</title>
<link href="//code.jquery.com/ui/1.10.2/themes/smoothness/jquery-ui.css" rel="Stylesheet"></link>
<script src="//code.jquery.com/jquery-2.2.0.min.js"></script>
<script src="//code.jquery.com/ui/1.10.2/jquery-ui.js" ></script>

  <script>
$(function() {
    $("#autocomplete").autocomplete({
        source:function(request, response) {
            $.getJSON("/autocomplete",
            {
                q: request.term, // in flask, "q" will be the argument to look for using request.args
            },
            function(data)
            {
                response(data.matching_results); // matching_results from jsonify
            }
        );
        },
        minLength: 2,
        select: function(event, ui) {
            console.log(ui.item.value); // not in your question, but might help later
        }
    });
})
  </script>
</head>
<body>

<div>
    <input name="autocomplete" type="text" id="autocomplete" class="form-control input-lg"/>
</div>

</body>
</html>
'''
    return html


@pocs.route("/pocs/10", methods=['GET'])
def poc10():

    tSQL = '''
SELECT GUID, ID, email, username, password, image_file,
    registered_on, email_confirmation_sent_on,
    email_confirmed, email_confirmed_on
FROM Users WHERE email = %s
'''
    tArgs = ('roger108@rl.co.za', )
    R = dbExecuteWithResults(tSQL, tArgs)
    R2 = {}
    R2['guid'] = R[0].decode()
    R2['id'] = R[1]
    R2['email'] = R[2].decode()
    R2['username'] = R[3].decode()
    R2['password'] = R[4].decode()
    R2['image_file'] = R[5].decode()
    R2['registered_on'] = R[6]
    R2['emailconfirmation_sent_on'] = R[7]
    R2['email_confirmed'] = R[8]
    R2['email_confirmed_on'] = R[9]

    html = f"""
    <h2>Proof of Concept 10 : DB Execute Prepared Statements</h2>
    <p>tSQL = {tSQL}</p>
    <p>Args = {tArgs}</p>"""

    for key in R2:
        html += f"<p>{key} = {R2[key]}</p>"

    return html


@pocs.route("/autocomplete", methods=['GET'])
def autocomplete():
    query = 'hat'
    query = '%' + query + '%'
    result = []

    result = []
    SQL = "SELECT ID, Name FROM ChenhallNomenclature WHERE Name LIKE %(query)s ORDER BY Name LIMIT 200"
    try:
        result = dbGetDict(SQL, {"query": query})
    except Exception as e:
        flash(f"Exception (Autocomplete SQL): {e} : {SQL}", 'danger')

    return jsonify(json_list=result)
