# markdownPOC.py
#
# Proof of Conecept and Exempkar tool for Markdown Page Design
#
# Markdown (MD) is a simplified syntax for creating HTML documents
# which reduces the amount of typing needed.
# The Markdown processeor converts te MD file to HTML to send to the web
#

import os
import markdown


# convert to HTML and send to browser
def markdownPOC(aFile):
    folder = os.path.dirname(os.path.realpath(__file__))
    md_file = os.path.join(folder, aFile)

    with open(md_file, "r", encoding="utf-8") as input_file:
        md_text = input_file.read()
    html = markdown(md_text)

    return html



