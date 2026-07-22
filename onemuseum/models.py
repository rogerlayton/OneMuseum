# from itsdangerous import TimedJSONWebSignatureSerializer as Serializer
from itsdangerous import URLSafeTimedSerializer as Serializer
from itsdangerous import BadSignature, SignatureExpired
from flask import current_app
from . import login_manager
from flask_login import UserMixin
from .dbutils import dbExecuteWithResults


@login_manager.user_loader
def load_user(user_id):
    tSQL = '''
SELECT GUID, ID, email, username, password, image_file,
    registered_on, email_confirmation_sent_on,
    email_confirmed, email_confirmed_on
FROM Users WHERE guid = %s
'''
    tArgs = (user_id, )
    R = dbExecuteWithResults(tSQL, tArgs)
    # TODO create User object from R elements
    user = User()
    user.id = R[0].decode()
    user.id2 = R[1]
    user.email = R[2].decode()
    user.username = R[3].decode()
    user.password = R[4].decode()
    user.image_file = R[5].decode()
    user.registered_on = R[6]
    user.email_confirmation_sent_on = R[7]
    user.email_confirmed = R[8]
    user.email_confirmed_on = R[9]

    return user


class User(UserMixin):
    __tablename__ = 'Users'
    id = None
    id2 = None
    username = None
    email = None
    image_file = None
    password = None
    registered_on = None
    email_confirmation_sent_on = None
    email_confirmed = None
    email_confirmed_on = None

    def get_reset_token(self, expires_sec=1800):
        s = Serializer(current_app.config['SECRET_KEY'], expires_sec)
        return s.dumps({'user_id': self.id}).decode('utf-8')

    @staticmethod
    def verify_reset_token(token):
        s = Serializer(current_app.config['SECRET_KEY'])
        try:
            user_id = s.loads(token)['user_id']
        except BadSignature:
            return None
        except SignatureExpired:
            return None

        tSQL = '''
SELECT GUID, ID, email, username, password, image_file,
    registered_on, email_confirmation_sent_on,
    email_confirmed, email_confirmed_on
FROM Users WHERE guid = %s
'''
        tArgs = (user_id, )
        R = dbExecuteWithResults(tSQL, tArgs)
        # TODO create User object from R elements
        user = User()
        user.id = R[0].decode()
        user.id2 = R[1]
        user.email = R[2].decode()
        user.username = R[3].decode()
        user.password = R[4].decode()
        user.image_file = R[5].decode()
        user.registered_on = R[6]
        user.email_confirmation_sent_on = R[7]
        user.email_confirmed = R[8]
        user.email_confirmed_on = R[9]
        return user

    def __repr__(self):
        return f"User('{self.username}', '{self.email}', '{self.image_file}')"
