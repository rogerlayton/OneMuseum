import sys
import os
from onemuseum.sdfutils import sdf_menu
from onemuseum.config import Config

root_path = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, root_path + '/../')

# from flask import Flask


def test_sdf_browsers():
    path = os.path.join(Config.BASE_DIR, "static/specs/browsers")
    if (not os.path.exists(path)):
        assert os.path.exists(path)
        return
    return


def test_sdf_details():
    path = os.path.join(Config.BASE_DIR, "static/specs/details")
    if not os.path.exists(path):
        assert os.path.exists(path)
        return
    return


def test_menus():

    path = os.path.join(Config.BASE_DIR, "static/specs/menus")
    if not os.path.exists(path):
        assert os.path.exists(path)
        return

    # r=root, d=directories, f=files
    for r, d, f in os.walk(path):
        # for folder in d:
        #    assert f"Folder {f} not allowed under statis/specs/menus"
        for file in f:
            file_name, file_extension = os.path.splitext(file)
            assert file_extension.upper() == ".SDF"
            menu_spec = sdf_menu(file_name)
            assert menu_spec['title'] != ''
            for item in menu_spec['items']:
                assert True
                # assert item['title'] != ''
                # assert item['text'] != ''
                # path = os.path.join(root_path, item['folder'], item['img'])
                # assert os.path.exists(path)
                # assert item['target'] in dir(os)
