from flask import render_template, url_for, flash, redirect, request, Blueprint, current_app
from flask_login import login_user, current_user, logout_user, login_required
from .. import bcrypt, mail
from ..models import User
from datetime import timedelta
from ..users.forms import SignUpForm, SignInForm, UpdateAccountForm, RequestResetForm, ResetPasswordForm
from ..users.utils import save_picture, send_reset_email, generate_confirmation_email
from ..dbutils import create_session, session_data, dbProcedure, dbInsert, dbUpdate, dbExecuteWithResults
from itsdangerous import URLSafeTimedSerializer
from itsdangerous.exc import BadSignature
from datetime import datetime
# from flask_mail import Message
from flask import copy_current_request_context
from threading import Thread


users = Blueprint('users', __name__)


@users.route("/signup", methods=['GET', 'POST'])
def signup():
    if current_user.is_authenticated:
        return redirect(url_for('main.home'))
    form = SignUpForm()
    if form.validate_on_submit():

        hashed_password = bcrypt.generate_password_hash(form.password.data).decode('utf-8')

        tFields = [
            'UserName', 'Email', 'Password', 'registered_on',
            'email_confirmation_sent_on', 'email_confirmed', 'email_confirmed_on']
        tValues = [
            form.username.data, form.email.data, hashed_password,
            datetime.now(), datetime.now(), False, None]
        dbInsert('Users', tFields, tValues)

        # user = User(username=form.username.data, email=form.email.data, password=hashed_password)
        # db.session.add(user)
        # db.session.commit()
        flash(f'Thank you for registering, {form.username.data}! Please check for the confirmation email.', 'success')

        @copy_current_request_context
        def send_email(message):
            with current_app.app_context():
                mail.send(message)

        # Send an email to the user that they have been registered
        msg = generate_confirmation_email(form.email.data)
        email_thread = Thread(target=send_email, args=[msg])
        email_thread.start()

        return redirect(url_for('users.signin'))
    return render_template('signup.html', title='Sign Up', form=form)


@users.route('/confirm/<token>')
def confirm_email(token):
    try:
        confirm_serializer = URLSafeTimedSerializer(current_app.config['SECRET_KEY'])
        email = confirm_serializer.loads(token, salt='email-confirmation-salt', max_age=1800)
    except BadSignature:
        flash('The confirmation link is invalid or has expired.', 'error')
        return redirect(url_for('users.signin'))

    user = user_get_by_email(email)

    if user.email_confirmed:
        flash('Account already confirmed. Please login', 'info')
    else:
        tFields = ['guid', 'email_confirmed', 'email_confirmed_on']
        tValues = [user.id, True, datetime.now()]
        dbUpdate('Users', tFields, tValues)
        flash('Thank you for confirming your email address!', 'success')
    return redirect(url_for('main.home'))


@users.route("/signin", methods=['GET', 'POST'])
def signin():
    #  NOTE: to clear out session from SQLite implementation
    # this was only required to be done ONCE when shifting from SQLite to MariaDB
    # [session.pop(key) for key in list(session.keys())]

    # print("SIGN IN", file=sys.stderr)
    if current_user.is_authenticated:
        return redirect(url_for('main.home'))
    form = SignInForm()
    if form.validate_on_submit():
        # try to find the user, using the email provided on signin form
        user = user_get_by_email(form.email.data)
        # if the user was found then check if the password (encyrpted) are the same
        if user and bcrypt.check_password_hash(user.password, form.password.data):
            # set the duration of the cookies to 30 minutes, to ensure that sessions timeout quickly
            # can also use browser password memory to move the remembered usercode and password when logging in
            login_user(user, remember=form.remember.data, duration=timedelta(minutes=30))
            next_page = request.args.get('next')
            flash('Sign In successful', 'success')
            create_session()
            return redirect(next_page) if next_page else redirect(url_for('main.home'))

        # FORCE LOGIN for administrators users only
        elif user.email == 'roger107@rl.co.za' or user.email == 'linkmunirih@gmail.com':
            # set the duration of the cookies to 30 minutes, to ensure that sessions timeout quickly
            # can also use browser password memory to move the remembered usercode and password when logging in
            login_user(user, remember=form.remember.data, duration=timedelta(minutes=30))
            next_page = request.args.get('next')
            flash('Sign In successful - using FORCED SIGN IN', 'success')
            create_session()
            return redirect(next_page) if next_page else redirect(url_for('main.home'))
        else:
            flash('Sign In unsuccessful. Please check your email and password', 'danger')
    return render_template('signin.html', title='Sign In', form=form)


def signin_reauth():

    if current_user.is_authenticated:
        return redirect(url_for('main.home'))
    form = SignInForm()
    if form.validate_on_submit():
        user = user_get(form.email.data)
        if user and bcrypt.check_password_hash(user.password, form.password.data):
            # set the duration of the cookies to 30 minutes, to ensure that sessions timeout quickly
            # can also use browser password memory to move the remembered usercode and password when logging in
            login_user(user, remember=form.remember.data, duration=timedelta(minutes=30))
            next_page = request.args.get('next')
            flash('Sign In successful')
            create_session()
            return redirect(next_page) if next_page else redirect(url_for('main.home'))
        # 4 OCT 2021: RL: force login on roger107 if password may be wrong
        elif user.email == 'roger107@rl.co.za':
            login_user(user, remember=form.remember.data, duration=timedelta(minutes=30))
            next_page = request.args.get('next')
            flash('Sign In successful - FORCED LOGIN')
            create_session()
            return redirect(next_page) if next_page else redirect(url_for('main.home'))
        else:
            flash('Sign In unsuccessful. Please check your email and password', 'danger')
    return render_template('signin.html', title='Sign In - Reauthorise after Timeout', form=form)


@users.route("/signout")
def signout():
    logout_user()
    return redirect(url_for('main.starter'))


@users.route("/account", methods=['GET', 'POST'])
@login_required
def account():
    form = UpdateAccountForm()
    if form.validate_on_submit():
        if form.picture.data:
            picture_file = save_picture(form.picture.data)
            current_user.image_file = picture_file
        current_user.username = form.username.data
        current_user.email = form.email.data
        # db.session.commit()
        flash('Your account has been updated!', 'success')
        return redirect(url_for('users.account'))
    elif request.method == 'GET':
        form.username.data = current_user.username
        form.email.data = current_user.email
    image_file = url_for('static', filename='profile_pics/' + current_user.image_file)
    return render_template('account.html', title='Account',
                           image_file=image_file, form=form)


@users.route('/resend_email_confirmation')
@login_required
def resend_email_confirmation():
    @copy_current_request_context
    def send_email(email_message):
        with current_app.app_context():
            mail.send(email_message)

    # Send an email to confirm the user's email address
    message = generate_confirmation_email(current_user.email)
    email_thread = Thread(target=send_email, args=[message])
    email_thread.start()

    flash('Email sent to confirm your email address.  Please check your email!', 'success')
    return redirect(url_for('users.account'))


@users.route("/user/<string:username>")
@login_required
def user_posts(username):
    user = user_get_by_username(username)
    return render_template('user_details.html', user=user)


@users.route("/reset_password", methods=['GET', 'POST'])
def reset_request():
    if current_user.is_authenticated:
        return redirect(url_for('main.home'))
    form = RequestResetForm()
    if form.validate_on_submit():
        user = user_get_by_email(form.email.data)
        send_reset_email(user)
        flash('An email has been sent with instructions to reset your password.', 'info')
        return redirect(url_for('users.signin'))
    return render_template('reset_request.html', title='Reset Password', form=form)


@users.route("/reset_password/<token>", methods=['GET', 'POST'])
def reset_token(token):
    if current_user.is_authenticated:
        return redirect(url_for('main.home'))
    user = User.verify_reset_token(token)
    if user is None:
        flash('That is an invalid or expired token', 'warning')
        return redirect(url_for('users.reset_request'))
    form = ResetPasswordForm()
    if form.validate_on_submit():
        hashed_password = bcrypt.generate_password_hash(form.password.data).decode('utf-8')
        user.password = hashed_password
        try:
            dbUpdate("Users", user.userid, ['password'], [user.password])
        except BaseException:  # the most generic exception - top of exception tree
            flash('Error in trying to update password')
        # db.session.commit()
        flash('Your password has been updated! You are now able to log in', 'success')
        return redirect(url_for('users.signin'))
    return render_template('reset_token.html', title='Reset Password', form=form)


@users.route("/history", methods=['GET'])
@login_required
def history():

    return "TODO: Display the history of usage of the OneMuseum"


@users.route("/favourite/<entity>/<guid>", methods=['GET', 'POST'])
@login_required
def favourite(entity, guid):

    user = current_user.id  # 'D3C661FA-6E5D-430D-B4CD-7B7C7BFDB764'
    # execute procedure UserEntityFavourite with myUser and GUID

    R = dbProcedure('UserEntityFavourite', args=(user, guid))
    # TODO use the storedresults from the call proc
    (ret, ) = R[0][0]
    if ret == 0:
        flash("You have removed this from your favourites", "info")
        session_data('FAV REM', '', '', ETName=entity, RefGUID=guid)
    else:
        flash("You have added this to your favourites", "info")
        session_data('FAV ADD', '', '', ETName=entity, RefGUID=guid)

    return redirect(f"/d/{entity}/{guid}")


def user_get_by_email(aEmail):
    return user_get('email', aEmail)


def user_get_by_username(aUserName):
    return user_get('username', aUserName)


def user_get(aField, aValue):
    ''' Get user record based on email '''

    tSQL = f'''
SELECT GUID, ID, email, username, password, image_file,
    registered_on, email_confirmation_sent_on,
    email_confirmed, email_confirmed_on
FROM Users WHERE `{aField}` = %s
'''
    tArgs = (aValue, )
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
