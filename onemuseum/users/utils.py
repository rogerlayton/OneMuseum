import os
import secrets
from PIL import Image
from flask import url_for, current_app
from flask_mail import Mail, Message
from itsdangerous import URLSafeTimedSerializer

# from __init__ import mail
from flask import render_template


def save_picture(form_picture):
    random_hex = secrets.token_hex(8)
    _, f_ext = os.path.splitext(form_picture.filename)
    picture_fn = random_hex + f_ext
    picture_path = os.path.join(current_app.root_path, 'static/profile_pics', picture_fn)

    output_size = (125, 125)
    i = Image.open(form_picture)
    i.thumbnail(output_size)
    i.save(picture_path)

    return picture_fn


def send_reset_email(user):
    mail = Mail()
    token = user.get_reset_token()

    msg = Message('Password Reset Request',
                  sender='noreply@onemuseum.net',
                  recipients=[user.email])
    msg.body = f'''To reset your password, visit the following link:
{url_for('users.reset_token', token=token, _external=True)}

If you did not make this request then simply ignore this email and no changes will be made.
'''
    mail.send(msg)


def generate_confirmation_email(user_email):
    ''' Generate the email to the user who have just registered
    for them to confirm that this is valid'''
    confirm_serializer = URLSafeTimedSerializer(current_app.config['SECRET_KEY'])

    confirm_url = url_for('users.confirm_email',
                          token=confirm_serializer.dumps(user_email, salt='email-confirmation-salt'),
                          _external=True)

    return Message(
        subject='OneMuseum - Confirm Your Email Address',
        sender='noreply@onemuseum.net',
        html=render_template('email_confirmation.html', confirm_url=confirm_url),
        recipients=[user_email])
