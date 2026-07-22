"""
BOA COMPONENTS: IMAGE HANDLER
(c) 2020 Roger Layton Associates

USAGE: 
- routing : i/GUID
- find the image with the name GUID.jpg
- send this back to the output
- this will called mainly within an IMG element
    - <img src='/i/GUID'..... />

V1: Retrieve only JPG files and from static/images using a GUID

REF: https://stackoverflow.com/questions/11017466/flask-to-return-image-stored-in-database
"""

import os
from flask import Blueprint
from flask import send_file

images = Blueprint('images', __name__)


@images.route('/i/<imageGUID>', methods=['GET'])
def get_image(imageGUID):

    # TODO: Extend to other types beyond JPG
    # TODO: Do lookup on DigitalObjects table to get details of object
    # TODO: Limit the rendering to images and similar, and pass others
    # such as (audio, etc.) onto other components for rendering

    # assume a single static source
    # TODO: link to the name of the repository and folder from DigitalObjects table
    folder = os.path.realpath('./static/images')
    filename = imageGUID

    filepath = os.path.join(folder, f'{filename}.jpg')
    if not os.path.exists(filepath):
        filepath = os.path.join(folder, '_missing_.jpg')

    return send_file(filepath, mimetype='image/jpg')
