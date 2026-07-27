from onemuseum import __version__, create_app

def test_version_string_is_set():
    # guards the single source of truth
    assert __version__

def test_version_injected_into_templates():
    # proves the context processor exposes it to Jinja
    app = create_app()
    with app.app_context():
        from flask import render_template_string
        rendered = render_template_string("{{ app_version }}")
    assert rendered == __version__