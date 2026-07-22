from flask import Flask
from flask_bcrypt import Bcrypt
from flask_login import LoginManager
from flask_mail import Mail
from flask_wtf.csrf import CSRFProtect

from .config import Config

bcrypt = Bcrypt()
login_manager = LoginManager()
login_manager.login_view = 'users.signin'
login_manager.refresh_view = 'users.signin_reauth'
login_manager.login_message = "Please signin to access this page"
login_manager.login_message_category = 'info'
mail = Mail()
csrf_protection = CSRFProtect()


def create_app(config_class=Config):
    app = Flask(__name__)
    app.config.from_object(config_class)

    bcrypt.init_app(app)
    login_manager.init_app(app)
    mail.init_app(app)
    csrf_protection.init_app(app)

    # Jinja environment customisations (moved from former app.py)
    from .dbutils import highlight_matches
    app.jinja_env.line_statement_prefix = '#'
    app.jinja_env.line_comment_prefix = '##'
    app.jinja_env.filters['highlight'] = highlight_matches

    # Register the per-request session/activity hook (moved from former app.py)
    from .request_hooks import register_request_hooks
    register_request_hooks(app)

    # Blueprints
    from .pocs.routes import pocs
    from .entities.routes import entities
    from .admin.routes import admin
    from .users.routes import users
    from .main.routes import main
    from .support.routes import support
    from .errors.handlers import errors
    from .categories.routes import categories
    from .images.routes import images

    app.register_blueprint(pocs)
    app.register_blueprint(entities)
    app.register_blueprint(admin)
    app.register_blueprint(users)
    app.register_blueprint(main)
    app.register_blueprint(errors)
    app.register_blueprint(categories)
    app.register_blueprint(support)
    app.register_blueprint(images)

    return app
