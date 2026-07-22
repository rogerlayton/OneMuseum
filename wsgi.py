"""WSGI entrypoint for OneMuseum.

Usage:
    gunicorn wsgi:app
    flask --app wsgi run           (development)
"""
from onemuseum import create_app

app = create_app()


if __name__ == '__main__':
    app.run(debug=True)
