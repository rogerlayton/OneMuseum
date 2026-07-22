Use OneMuseum;

INSERT INTO Users(UserName, Password, Email, FullName)
VALUES('TESTUSER', '', 'testuser@rl.co.za', 'Test User');

SELECT * FROM Users WHERE UserName = 'TESTUSER';



SELECT * FROM DigitalFormats;

SELECT * FROM EntityTypes ORDER BY ETID;

SELECT * FROM PerOrgs;
SELECT * FROM Users;


SELECT * FROM PerOrgTypes

SELECT * FROM CurriculumElements WHERE Code = 'VA491'

SELECT * FROM Lessons

SELECT * FROM Categorizations

SELECT * FROM Museums ORDER BY Name;

SELECT m.Name, c.Name  FROM COllections c
JOIN Museums m ON c.MuseumID = m.GUID;


Use OneMuseum;


FLUSH TABLES;

SELECT * FROM Museums;



SELECT * FROM Categorizations WHERE RefGUID = 'D096CAD4-D7B3-D81E-2239-5E7B16CC69D8'



SELECT e.GUID, e.ETName, e.EntityName, e.Museum, c.CategoryValue, c.CategoryValueExt
FROM EntityNames e
JOIN Categorizations c ON c.RefGUID = e.GUID
WHERE CategoryValueID = '7229963C-7DEE-FFFF-FE94-8C6CAD256CDC'




CALL GenCategories('7229963C-7DEE-FFFF-FE94-8C6CAD256CDC', 'D3C661FA-6E5D-430D-B4CD-7B7C7BFDB764')


SELECT * FROM categorizations

Use OneMuseum;

CALL GenDetails ('curriculumelement', '5FA326E3-0CD5-4A85-9EE3-BFE9D08F97EE', 'D3C661FA-6E5D-430D-B4CD-7B7C7BFDB764');



CALL GenDetails ('lesson', 'D90DCDDB-FD39-5CF7-7F4B-9C256D1DF5BA', 'D3C661FA-6E5D-430D-B4CD-7B7C7BFDB764');


SELECT ID, GUID, UserID, FileName, MuseumID, Museum,
	DateStarted, DateEnded, NumLines, NumErrors,
    Content, Status
FROM InputFiles
WHERE UserID = '24b405a3-352a-d3a7-7df2-f5ba3f3223c3';


    
    
CALL UPLOAD_InputFile ('test1.sdf', 'Museum of Mathematics', '24b405a3-352a-d3a7-7df2-f5ba3f3223c3', 2, '[(1, 2, 3), (4, 5, 6), (7, 8, 9)]')

SELECT * FROM InputFiles ORDER BY ID DESC;


CALL UPLOAD_DigitalObject(565, 'F2D441AD-52B4-060D-3670-A6F9058C406C', 'Berni_Searle.jpg', 'test image')

-- EEB3395E-5185-FEBB-87C6-A17FA2E06E63
SELECT * FROM Lessons;
SELECT * FROM DigitalObjects;
SELECT * FROM Categorizations;


-- CAPS, VA491

SELECT ce.GUID AS guid, ce.Code, ce.Name
FROM Curricula c
JOIN CurriculumElements ce ON ce.CurriculumID = c.GUID
WHERE c.Code = 'CAPS'
AND ce.Code = 'VA491'


SELECT ce.GUID AS guid
FROM Curricula c
JOIN CurriculumElements ce ON ce.CurriculumID = c.GUID
WHERE c.Code = 'CAPS'
AND ce.Code = ' VA491'


SELECT l.GUID as guid,
   IsUserFavourite(%(userid)s, l.GUID) AS Star,
   m.Name As Museum,
   l.Name AS Lesson,
   l.Description AS Description,
   JoinStrings(lt.Name, l.LessonType) AS LessonType,
   JoinStrings(cs.Name, ce.Name) AS Subject,
   JoinStrings(cl.Name, ce.CurriculumLevel) AS Grade
FROM Lessons l
 LEFT JOIN Museums m on l.MuseumID = m.GUID
 LEFT JOIN LessonTypes lt ON l.LessonTypeID = lt.GUID
 LEFT JOIN Categorizations c ON l.GUID = c.RefGUID
 
 


 LEFT JOIN CurriculumSubjects cs on l.CurriculumSubjectID = cs.GUID
 LEFT JOIN CurriculumElements ce on l.CurriculumElementID = ce.GUID
 LEFT JOIN CurriculumLevels cl ON ce.CurriculumLevelID = cl.GUID
 
 
 
 
 
SELECT TABLE_SCHEMA, TABLE_NAME, TABLE_TYPE
FROM INFORMATION_SCHEMA.TABLES
-- WHERE TABLE_TYPE='BASE TABLE'
-- AND TABLE_SCHEMA='ETHERBASEMUMA21'
ORDER BY TABLE_NAME


SELECT * FROM etherbasemehsa21.itemtypes2;

USe OneMuseum;

SELECT * FROM DigitalObjects ORDER BY GUID

SELECT * FROM DigitalObjectLinks

DELETE FROM DigitalObjects
WHERE FIleName LIKE ('Berni_%')
 
SELECT * FROM Lessons

DELETE FROM Lessons
WHERE Name LIKE 'John%'
OR Name LIKE 'Berni%'
OR Name LIke 'test%'