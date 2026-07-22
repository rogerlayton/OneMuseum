from flask import render_template, Blueprint
from flask_login import login_required
from ..config import Config
# from sdfutils import sdf_support
import markdown
import os

support = Blueprint('support', __name__)


@support.route("/s/<entity>")
@login_required
def show(entity):

    root = Config.BASE_DIR
    folder = os.path.join(root, "static/pages")

    #  look for file in static/support/*.MD or *.SDF

    file_md = os.path.join(folder, entity + ".md")
    file_sdf = os.path.join(folder, entity + ".sdf")

    #  Markdown MD - process the file using the Python-Markdown

    if os.path.exists(file_md):

        with open(file_md, "r", encoding="utf-8") as input_file:
            text = input_file.read()
        html = markdown.markdown(text)

    # SDF - process using sdf_support processore

    elif os.path.exists(file_sdf):

        # page_spec = sdf_support(file_sdf)
        html = "CANNOT YET PROCESS SDF PAGE FILES"

        # process the content in the SDF file

    else:

        html = f"CANNOT FIND THE FILE FOR THE PAGE {entity}"

    return render_template('support.html', page=entity, content=html)


@support.route("/ss/<entity>")
def show_starter(entity):
    """Support pages available from the Starter page, not requiring a log in"""

    root = Config.BASE_DIR
    folder = os.path.join(root, "static/pages/starter")

    #  look for file in static/support/*.MD or *.SDF

    file_md = os.path.join(folder, entity + ".md")
    file_sdf = os.path.join(folder, entity + ".sdf")

    #  Markdown MD - process the file using the Python-Markdown

    if os.path.exists(file_md):

        with open(file_md, "r", encoding="utf-8") as input_file:
            text = input_file.read()
        html = markdown.markdown(text)

    # SDF - process using sdf_support processore

    elif os.path.exists(file_sdf):

        # page_spec = sdf_support(file_sdf)
        html = "CANNOT YET PROCESS SDF PAGE FILES"

        # process the content in the SDF file

    else:

        html = f"CANNOT FIND THE SUPPORT/HELP FILE - {entity}"

    return render_template('support.html', page=entity, content=html, isstarter=1)
