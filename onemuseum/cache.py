# cache.py
#
# Enable storage, retrieval, and replacement of cached files
#
# informed by: https://stackoverflow.com/questions/3895359/python-global-object-cache
#
# cache.add name, content: add content into cache accessed by name
# cache.get name: get the content from the name, or get the default
# cache.remove name: remove the entry in cache for name, if it exists
#

_entities = {}


class Cache(object):
    @staticmethod
    def add(name, content):
        _entities.update({name: content})

    @staticmethod
    def get(name, default=None):
        return _entities.get(name, default)

    @staticmethod
    def remove(name):
        _entities.pop(name, None)

    @staticmethod
    def get_all():
        return _entities

    @staticmethod
    def count():
        return len(_entities)

    @staticmethod
    def clear():
        _entities.clear()
