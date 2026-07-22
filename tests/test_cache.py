import sys
import os
from onemuseum.cache import Cache


myPath = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, myPath + '/../')


def test_cache_clear():
    Cache.clear()
    assert Cache.count() == 0


def test_cache_add():
    Cache.clear()
    Cache.add('key1', 'content1')
    assert 'key1' in Cache.get_all()
    assert Cache.get('key1') == 'content1'
    assert Cache.count() == 1


def test_cache_remove():
    Cache.clear()
    Cache.add('key1', 'content1')
    Cache.add('key2', 'content2')
    Cache.remove('key1')
    assert 'key1' not in Cache.get_all()
    assert 'key2' in Cache.get_all()
    assert Cache.get('key2') == 'content2'
    assert Cache.count() == 1


def test_cache_get():
    Cache.clear()
    Cache.add('key1', 'content1')
    Cache.add('key2', 'content2')
    c1 = Cache.get('key1')
    c2 = Cache.get('key2')
    assert c1 == 'content1'
    assert c2 == 'content2'
    assert Cache.count() == 2


def test_cache_get_all():
    Cache.clear()
    Cache.add('key1', 'content1')
    Cache.add('key2', 'content2')
    all = Cache.get_all()
    assert all == {'key1': 'content1', 'key2': 'content2'}
    assert all == {'key2': 'content2', 'key1': 'content1'}
    assert Cache.count() == 2
