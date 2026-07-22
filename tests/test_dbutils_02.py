# test_dbutils_02.py
#
# Second round of tests on the functions within dbutils
#

import sys
import os
from onemuseum.dbutils import dbGetRow  # , dbGetAll

myPath = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, myPath + '/../')


def test_getrow():
    ''' Retrieve a single row based on GUID'''
    R = dbGetRow('Users', '217B6299-20CC-6D09-C00E-935EAA1995FC')
    # 217B6299-20CC-6D09-C00E-935EAA1995FC
    assert R[0] == '217B6299-20CC-6D09-C00E-935EAA1995FC'
    assert R[2] == 24
    assert R[4] == "TESTUSER"
    assert R[5] == 'testuser@rl.co.za'
    assert R[6] == 'default.jpg'
