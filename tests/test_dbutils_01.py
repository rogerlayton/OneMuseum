import sys
import os
from onemuseum.dbutils import dbGetCategoryName, dbExists

myPath = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, myPath + '/../')


def test_categoryname_1():
    ''' CategoryName - known element '''
    (RefETID, Class, ClassName, Name) = dbGetCategoryName('BD9E5F86-9491-451F-871F-845B56486ED0')
    assert RefETID == 115
    assert Class == 'namedevent'
    assert ClassName == 'Named Event'
    assert Name == '2004 Tsunami'


def test_categoryname_2():
    ''' Category Name - unknown element '''
    R = dbGetCategoryName('BD9E5F86-9491-451F-871F-845B56486ED9')
    assert R is None


def test_exists_11():
    ''' Check if user exists with guid '''
    found = dbExists('Users', 'guid', '217B6299-20CC-6D09-C00E-935EAA1995FC')
    assert found is True


def test_exists_12():
    ''' Check if user exists with guid '''
    found = dbExists('Users', 'guid', 'DUMMY')
    assert found is False


def test_exists_21():
    ''' Check if user exists with email '''
    found = dbExists('Users', 'email', 'roger@rl.co.za')
    assert found is True


def test_exists_22():
    ''' Check if user exists with email '''
    found = dbExists('Users', 'email', 'DUMMY')
    assert found is False


def test_exists_31():
    ''' Check if user exists with email '''
    found = dbExists('Users', 'username', 'TESTUSER')
    assert found is True


def test_exists_32():
    ''' Check if user exists with email '''
    found = dbExists('Users', 'username', 'DUMMY')
    assert found is False
