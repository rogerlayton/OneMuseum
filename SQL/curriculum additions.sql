-- {6A2DC009-6438-4ECA-9FD6-2BF81A23139E}
USE OneMuseum;

SELECT * FROM curriculumelements 
WHERE GUID LIKE '6A%'
;

INSERT INTO curriculumelements(
	GUID, ParentID, CurriculumElementTypeID, CurriculumElementType, CurriculumID, Curriculum,
    CurriculumSubjectID, CurriculumSubject, CurriculumLevelID, CurriculumLevel,
    Code, Name, Content, Seq, Hours, Term1, Term2, Term3, Term4)
VALUES (
	'6A2DC009-6438-4ECA-9FD6-2BF81A23139E', NULL, 'A86CFE96-7A7D-4177-929D-CFF3349BCDB8', NULL, '86E85569-DCAB-410A-96D5-1F535671381F', NULL,
    '2711855B-80A4-490F-B1B2-A1DBA8C948E0', NULL, '3B4CEE6C-156E-4FF8-9421-9652FB386D52', NULL,
    'IT5', 'Data Information and Management', NULL, '5', NULL, 0, 0, 0, 0)


INSERT INTO curriculumelements(  GUID, ParentID, CurriculumElementTypeID, CurriculumElementType, CurriculumID, Curriculum,     CurriculumSubjectID, CurriculumSubject, CurriculumLevelID, CurriculumLevel,     Code, Name, Content, Seq, Hours, Term1, Term2, Term3, Term4) VALUES (  '6A2DC009-6438-4ECA-9FD6-2BF81A23139E', NULL, 'A86CFE96-7A7D-4177-929D-CFF3349BCDB8', NULL, '86E85569-DCAB-410A-96D5-1F535671381F', NULL,     '2711855B-80A4-490F-B1B2-A1DBA8C948E0', NULL, '3B4CEE6C-156E-4FF8-9421-9652FB386D52', NULL,     'IT5', 'Data Information and Management', NULL, '5', NULL, 0, 0, 0, 0)


Error Code: 1452. Cannot add or update a child row: a foreign key constraint fails
 (`onemuseum`.`curriculumelements`, CONSTRAINT `curriculumelements_ibfk_3` FOREIGN KEY (`CurriculumSubjectID`) 
 REFERENCES `curriculumsubjects` (`GUID`))


INSERT INTO curriculumsubjects(GUID, ParentID, CurriculumID, Curriculum,
Code, Name, Description)
VALUES ('2711855B-80A4-490F-B1B2-A1DBA8C948E0', NULL, '86E85569-DCAB-410A-96D5-1F535671381F', NULL,
'IT', 'Information Technology', NULL)


INSERT INTO `curriculumsubjects` (GUID, ParentID, CurriculumID, Curriculum, Code, Name, Description)
VALUES ('E18C70E7-3E2E-482E-BF69-5F178B07C004', NULL, '86E85569-DCAB-410A-96D5-1F535671381F', NULL, 'NA', 'Nautical Science', NULL)


