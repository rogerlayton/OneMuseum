USE OneMuseum;


		-- 2 : get all of the category data associated with this entity
	SELECT
		e.EntityName AS Class,
		JoinStrings(c.CategoryValue, c.CategoryValueExt) AS `Category`,
        c.CategoryValueID AS CategoryValueID,
        DateDescription,
        Location,
        Priority		
    FROM Categorizations c
    LEFT JOIN EntityTypes e ON c.CategoryETID = e.ETID
    WHERE c.CategoryValueID = 'EAA5E41A-5180-46D3-95A4-C33693E61063'
    ORDER BY 1, 2;


SELECT * FROM Categorizations



SELECT COUNT(*)
FROM Categorizations c
CROSS JOIN Users u
LEFT JOIN EntityTypes e ON c.CategoryETID = e.ETID
ORDER BY c.CategoryClass, CategoryValue



SELECT c.GUID as guid, IsUserFavourite('{userid}', c.GUID) AS Star,

FROM Categorizations c
CROSS JOIN Users u
LEFT JOIN EntityTypes e ON c.CategoryETID = e.ETID ORDER BY c.Name
LIMIT 20 OFFSET 0




SELECT c.GUID as guid,
    IsUserFavourite('D3C661FA-6E5D-430D-B4CD-7B7C7BFDB764', c.GUID) AS Star, 
    JoinStrings(c.CategoryValue, c.CategoryValueExt) AS Name,
    en.ETName AS `Type`,
    en.EntityName AS `Name`,
    c.CategoryValueID AS CategoryValueID,
    DateDescription, DateMin, DateMax,
    Location,
    Priority,
FROM Categorizations c
CROSS JOIN Users u
LEFT JOIN EntityNames en on c.RefGUID = en.GUID
WHERE  (   c.CategoryValueID = 'EAA5E41A-5180-46D3-95A4-C33693E61063' AND  u.GUID = 'D3C661FA-6E5D-430D-B4CD-7B7C7BFDB764' )
ORDER BY  en.ETName, JoinStrings(c.CategoryValue, c.CategoryValueExt)

SELECT * FROM EntityNames
WHERE GUID = '3F26C4F3-2C0F-493C-B235-40AED60D0F07'

SELECT * FROM SessionData ORDER BY ID;


SELECT * FROM Sessions ORDER BY ID DESC



INSERT INTO SessionData(SessionID, Type, URL, SearchString, ETName, EntityName)
VALUES ('0c565e72-efdd-4982-8b77-9b36f57168e1', 'BROWSER', '', 'dit', 'museums', '')


SELECT REfETID, Class, Name FROM CategoriesAll WHERE GUID = 'BD9E5F86-9491-451F-871F-845B56486ED0'


Error Code: 1452. Cannot add or update a child row: a foreign key constraint fails (`onemuseum`.`sessiondata`, CONSTRAINT `sessiondata_ibfk_1` FOREIGN KEY (`SessionID`) REFERENCES `sessions` (`GUID`))


USE OneMuseum;

SELECT ne.Name, ne2.Name
FROM NamedEvents ne
JOIN NamedEvents ne2 ON ne.ParentID = ne2.GUID


DELIMITER //
CREATE TABLE Sessions
(
	GUID CHAR(36) NOT NULL DEFAULT '#NONE#' PRIMARY KEY,
    ID SERIAL,
    UserID CHAR(36) NOT NULL,
    DateStarted DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP(),
    DateEnded DATETIME NULL,
    IsTimedOut BIT NOT NULL DEFAULT 0;
    
    
INSERT INTO Sessions(UserID) VALUES ('D3C661FA-6E5D-430D-B4CD-7B7C7BFDB764')

SELECT * FROM NamedEvents;

SELECT * FROM Sessions ORDER BY ID DESC;


SELECT * FROM SessionData ORDER BY ID DESC;


SELECT ce.GUID as guid, IsUserFavourite('%(userid)s', c.GUID) AS Star, JoinStrings(cep.Name, cept.Name) AS Parent, ce.Code AS Code, ce.Name AS Element, JoinStrings(cet.Name, ce.CurriculumElementType) AS Type, cl.Name AS Grade, JoinStrings(cs.Name, ce.CurriculumSubject) AS Subject, JoinStrings(c.Name, ce.Curriculum) AS `Curr.` FROM CurriculumElements ce LEFT JOIN CurriculumElementTypes cet ON ce.CurriculumElementTypeID = cet.GUID LEFT JOIN CurriculumElements cep ON ce.ParentID = cep.GUID LEFT JOIN CurriculumElementTypes cept ON cep.CurriculumElementTypeID = cept.GUID LEFT JOIN Curricula c ON ce.CurriculumID = c.GUID LEFT JOIN CurriculumLevels cl ON ce.CurriculumLevelID = cl.GUID LEFT JOIN CurriculumSubjects cs on ce.CurriculumSubjectID = cs.GUID ORDER BY c.Name, cs.Name, cl.Seq, ce.Seq LIMIT 20 OFFSET 0

INSERT INTO UserROleTypes (GUID, Code, Name, Description)
VALUES ('4EC26AE4-06D3-49B4-8D86-424ACF305341', 'T', '_TEST_USER', 'User for system testing');


INSERT INTO Users (GUID, UserRoleTypeID, UserName, DisplayName, Email, Password, UserStatus)
VALUES ('814ADE37-8616-42D8-853B-F348E8FF2CB4', '4EC26AE4-06D3-49B4-8D86-424ACF305341', '_TEST_USER', 'TEST USER', 'test@example.com', 'password', 1);


			SELECT SQL_CALC_FOUND_ROWS RefETID, Class AS ETName, Name AS EntityName, '' AS Museum
			FROM CategoriesAll
			WHERE GUID = '0BF6FFD0-A4AC-4020-BBA7-13B2562B1BA0';
        
        
        