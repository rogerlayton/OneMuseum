import os


class Config:
    SECRET_KEY = os.environ.get('SECRET_KEY')
    MAIL_SERVER = os.environ.get('MAIL_SERVER')
    MAIL_PORT = 587
    MAIL_USE_TLS = True
    MAIL_USERNAME = os.environ.get('MAIL_USERNAME')
    MAIL_PASSWORD = os.environ.get('MAIL_PASSWORD')
    BASE_DIR = os.path.abspath(os.path.dirname(__file__))
    MYSQLCONN_USER = os.environ.get('MYSQLCONN_USER')
    MYSQLCONN_PASSWORD = os.environ.get('MYSQLCONN_PASSWORD')
    MYSQLCONN_HOST = os.environ.get('MYSQLCONN_HOST')
    MYSQLCONN_PORT = os.environ.get('MYSQLCONN_PORT')
    MYSQLCONN_DATABASE = os.environ.get('MYSQLCONN_DATABASE')
