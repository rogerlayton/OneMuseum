import sys
import os

myPath = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, myPath + '/../')


""" def test_config_item():
    app = Flask(__name__)
    app.config.from_object(Config)
    assert Config.SECRET_KEY is not None
    assert 'FLASK_APP' in Config
    assert 'MYSQL_USER' in Config
    assert 'MAIL_HOST' in Config """
