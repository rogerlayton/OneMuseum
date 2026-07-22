import sys
import os

from onemuseum.dbutils import dbOpen, dbClose, dbProcedure

"""
INSERT INTO UserRoleTypes (GUID, Code, Name, Description)
VALUES ('4EC26AE4-06D3-49B4-8D86-424ACF305341', 'T', '_TEST_USER', 'User for system testing');


INSERT INTO Users (GUID, UserRoleTypeID, UserName, DisplayName, Email, Password, UserStatus)
VALUES ('814ADE37-8616-42D8-853B-F348E8FF2CB4', '4EC26AE4-06D3-49B4-8D86-424ACF305341', '_TEST_USER', 'TEST USER', 'test@example.com', 'password', 1);
"""


def test_setfavourite():
    """
    userid = GetTestUserID()

    result = dbProcedure('UserEntityFavourite', {"userid": userid, "guid": guid})
    """
    assert True
