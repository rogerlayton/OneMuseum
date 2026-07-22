import re

def highlight_matches(text, query):
    """ https://gist.github.com/alexgleason/5935726472c3823d1c45 """
    def span_matches(match):
        html = '<span class="query">{0}</span>'
        return html.format(match.group(0))
    return re.sub(query, span_matches, text, flags=re.I)

