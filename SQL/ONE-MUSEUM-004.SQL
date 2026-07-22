/*
** ONE-MUSEUM.COM
** SCRIPT: ONE-MUSEUM-004.SQL : STORED PROCEDURES AND FUNCTIONS
**
*/

USE OneMuseum;

DELIMITER //
DROP VIEW IF EXISTS EntityNames //
CREATE VIEW EntityNames
AS
-- union view of all types of entities in OneMuseum
	SELECT n.GUID, 515 AS RefETID, 'museum' AS ETName, n.Name AS EntityName, Name AS Museum
    FROM Museums n
    UNION
    SELECT c.GUID, 525 AS RefETID, 'collection' AS ETName, c.Name AS EntityName, m.Name as Museum
    FROM Collections c
    LEFT JOIN Museums m ON c.MuseumID = m.GUID
    UNION
    SELECT i.GUID, 535 AS RefETID, 'item' AS ETName, i.Name AS EntityName, m.Name AS Museum
    FROM Items i
    LEFT JOIN Collections c ON i.CollectionID = c.GUID
    LEFT JOIN Museums m ON c.MuseumID = m.GUID
    UNION
    SELECT e.GUID, 545 AS RefETID, 'exhibition' AS ETName, e.Name AS EntityName, m.Name AS Museum
    FROM Exhibitions e
    LEFT JOIN Museums m ON e.MuseumID = m.GUID
    UNION
    SELECT s.GUID, 555 AS RefETID, 'story' AS ETName, s.Name AS EntityName, m.Name AS Museum
    FROM Stories s
    LEFT JOIN Museums m ON s.MuseumID = m.GUID
    UNION
    SELECT l.GUID, 565 AS RefETID, 'lesson' AS ETName, l.Name AS EntityName, m.Name AS Museum
    FROM Lessons l
    LEFT JOIN Museums m ON l.MuseumID = m.GUID
    UNION
    SELECT b.GUID, 585 AS RefETID, 'biography' AS ETName, b.Title AS EntityName, m.Name AS Museum
    FROM Biographies b
    LEFT JOIN Museums m ON b.MuseumID = m.GUID
    UNION
    SELECT p.GUID, 575 AS RefETID, 'publication' AS ETName, p.Title AS EntityName, m.Name AS Museum
    FROM Publications p
    LEFT JOIN Museums m ON p.MuseumID = m.GUID
    UNION
    SELECT me.GUID, 595 AS RefETID, 'museum event' AS ETName, me.Title AS EntityName, m.Name AS Museum
    FROM MuseumEvents me
    LEFT JOIN Museums m ON me.MuseumID = m.GUID
    UNION
    SELECT e.GUID, 605 AS RefETID, 'expert' AS ETName, IFNULL(p.Name, e.PerOrg) AS EntityName, m.Name AS Museum
    FROM Experts e
    LEFT JOIN Museums m ON e.MuseumID = m.GUID
    LEFT JOIN PerOrgs p ON e.PerOrgID = p.GUID
//



DELIMITER //
DROP VIEW IF EXISTS CategoriesAll //
CREATE VIEW CategoriesAll
AS
-- union view of all classes of categories in OneMuseum

	SELECT c.GUID, 115 AS RefETID, 'namedevent' AS Class,
		c.Code AS Code, c.Name AS Name
    FROM NamedEvents c
    UNION
    
	SELECT c.GUID, 107 AS RefETID, 'namedplace' AS Class,
		c.Code AS Code, c.Name AS Name
    FROM NamedPlaces c
    UNION
    
	SELECT c.GUID, 125 AS RefETID, 'perorg' AS Class,
		'' AS Code, c.Name AS Name
    FROM PerOrgs c
    UNION

	SELECT c.GUID, 145 AS RefETID, 'subject' AS Class,
		''AS Code, c.Name AS Name
    FROM Subjects c
    UNION

	SELECT c.GUID, 155 AS RefETID, 'curriculumsubject' AS Class,
		c.Code AS Code, c.Name AS Name
    FROM CurriculumSubjects c
    UNION

	SELECT c.GUID, 155 AS RefETID, 'curriculumelement' AS Class,
		c.Code AS Code, c.Name AS Name
    FROM CurriculumElements c
    UNION
    
	SELECT c.GUID, 531 AS RefETID, 'itemtype' AS Class,
		c.Code AS Code, c.Name AS Name
    FROM ItemTypes c

//



DELIMITER //
DROP PROCEDURE IF EXISTS UserEntityFavourite //
CREATE PROCEDURE UserEntityFavourite (
	aUserID CHAR(36),
    aEntityGUID CHAR(36))
COMMENT 'If this entity linked to user then DELETE, else INSERT and find associated values to store'
BEGIN
	
    DECLARE tRefETID CHAR(36);
    DECLARE tETName VARCHAR(100);
    DECLARE tEntityName VARCHAR(200);
	DECLARE tMuseum VARCHAR(100);
    DECLARE tRet INT;
    DECLARE tFound INT;
    
    SET tFound = 0;
	SET tRet = 0;
    
		-- if already exists then remove this entry
    IF EXISTS (SELECT * FROM UserEntities WHERE UserID = aUserID AND RefGUID = aEntityGUID) THEN
		DELETE FROM UserEntities
		WHERE UserID = aUserID
		AND RefGUID = aEntityGUID;
	
        
        -- if not exists, then add this entry
	ELSE
		SELECT SQL_CALC_FOUND_ROWS RefETID, ETName, EntityName, Museum
		INTO tRefETID, tETName, tEntityName, tMuseum
		FROM EntityNames
		WHERE GUID = aEntityGUID;
        
        IF FOUND_ROWS() = 0 THEN
			SELECT SQL_CALC_FOUND_ROWS RefETID, Class, Name, ''
			INTO tRefETID, tETName, tEntityName, tMuseum
			FROM CategoriesAll
			WHERE GUID = aEntityGUID;
            
            IF FOUND_ROWS() > 0 THEN
				SET tFound = 1;
			END IF;
            
		ELSE
			SET tFound = 1;
		END IF;
            
		SET tRet = -1; -- cannot find the GUID to update - this is a system error - perhaps problem with the views for lookup
        
		IF tFound = 1 THEN
			INSERT INTO UserEntities (UserID, RefETID, ETName, RefGUID, EntityName, Museum)
			VALUES (aUserID, tRefETID, tETName, aEntityGUID, tEntityName, tMuseum);
		
			SET tRet = 1;
		END IF;
        
    END IF;
    
    -- return the result for the AJAX command
    SELECT tRet AS Result;

END
//


DELIMITER //
DROP FUNCTION IF EXISTS IsUserFavourite
//
CREATE FUNCTION IsUserFavourite (
		aUserID CHAR(36),
        aEntityID CHAR(36)
)
RETURNS int
BEGIN
	DECLARE tFound int;
    SET tFound = 0;
    
    IF EXISTS
    (
		SELECT *
        FROM UserEntities
        WHERE UserID = aUserID
        AND RefGUID = aEntityID
	) THEN
        
        SET tFound = 1;
        
	END IF;
    
	RETURN tFound;
END
//


DELIMITER //
CREATE FUNCTION JoinStrings (
	aStr1 VARCHAR(200),
    aStr2 VARCHAR(200)
)
RETURNS VARCHAR(500)
BEGIN

	DECLARE tStr VARCHAR(500);
    
	IF aStr1 IS NULL OR aStr1 = '' THEN
		IF aStr2 IS NULL OR aStr2 = '' THEN
			SET tStr = '';
		ELSE
			SET tStr = aStr2;
		END IF;
	ELSE
		IF aStr2 IS NULL OR aStr2 = '' THEN
			SET tStr = aStr1;
		ELSE
			IF aStr1 = aStr2 THEN
				SET tStr = aStr1;
			ElSE
				SET tStr = CONCAT(aStr1, '/', aStr2);
            END IF;
		END IF;
	END IF;
    
    RETURN tStr;
END
//


DELIMITER //
DROP PROCEDURE IF EXISTS GenDetails //
CREATE PROCEDURE GenDetails (
	aETName VARCHAR(100),
    aEntityGUID CHAR(36),
    aUserID CHAR(36))
COMMENT 'Extract all of the data for the DETAILS form for this entity.
This includes the core data from the entity table; all category data; all common data; and all digital images.
These are produced as different SELECT statements.'
BEGIN
    
		-- 1 : retrieve all of the core data for this entity
        -- the core data is that associated with the fields and the basic relationships
        -- of the row in the table - these are formalised in Details VIEWS specific for each type
        -- such as a VIEW MuseumDetails - if this does not exist this will procedure will
        -- NOTE: this approach below uses Prepared Statememts in MySQL which is the only way
        -- to create runtime queries - similar to EXEC(string) in MSSQL.
	SET @SQL = CONCAT('SELECT * FROM ', aETName, 'Details WHERE GUID = ? AND UserID = ? LIMIT 1');
    -- SELECT @SQL;
    
	PREPARE st1 FROM @SQL;
    -- must put into local variable - does not work with arguments directly
	SET @GUID = aEntityGUID;
    SET @UserID = aUserID;
    EXECUTE st1 USING @GUID, @UserID;
	DEALLOCATE PREPARE st1;
    
		-- 2 : get all of the category data associated with this entity
	SELECT
		e.EntityName AS Category,
        ca.Name AS Name,
		JoinStrings(c.CategoryValue, c.CategoryValueExt) AS `Value`,
        c.CategoryValueID AS CategoryValueID,
        DateDescription, Location, Priority		
    FROM Categorizations c
    LEFT JOIN CategoriesAll ca ON c.CategoryValueID = ca.GUID
    LEFT JOIN EntityTypes e ON c.CategoryETID = e.ETID
    WHERE RefGUID = aEntityGUID;

		-- 3 : retrieve all of the common data associated with this entity
    CALL GetCommonData (aEntityGUID);

		-- 4 : retrieve all digital images for this entity
        -- TODO

END
//

/*

	SELECT
		e.EntityName AS Category,
        ca.Name AS Value1,
		JoinStrings(c.CategoryValue, c.CategoryValueExt) AS Value2,
        c.CategoryValueID AS CategoryValueID,
        DateDescription, Location, Priority		
    FROM Categorizations c
    LEFT JOIN CategoriesAll ca ON c.CategoryValueID = ca.GUID
    LEFT JOIN EntityTypes e ON c.CategoryETID = e.ETID
    WHERE c.RefGUID = 'DDDAAFC0-E4CE-5015-76AE-8EF17269A9D8';
    

	SELECT *			
    FROM Categorizations c
    WHERE c.RefGUID = 'DDDAAFC0-E4CE-5015-76AE-8EF17269A9D8';
    
    

CALL GenDetails('lesson', 'D90DCDDB-FD39-5CF7-7F4B-9C256D1DF5BA', '')

SELECT * FROM lessonDetails WHERE GUID = 'D90DCDDB-FD39-5CF7-7F4B-9C256D1DF5BA'
AND UserID = '24b405a3-352a-d3a7-7df2-f5ba3f3223c3' LIMIT 1

SHOW PROCESSLIST

SHOW GLOBAL STATUS

SHOW VARIABLES

FLUSH TABLES


SELECT * FROM namedeventDetails WHERE GUID = ? AND UserID = ? lIMIT 1

*/

DELIMITER //
DROP PROCEDURE IF EXISTS GetCommonData
//
CREATE PROCEDURE GetCommonData (aGUID CHAR(36))
COMMENT 'Return all common data for a specific EntityGUID'
BEGIN
	SELECT 1 AS S, n.GUID AS GUID,
		nt.Seq AS Seq,
		JoinStrings(nt.Name, n.NoteType) As Type,
		n.Note AS Value
	FROM Notes n
	LEFT JOIN NoteTypes nt on n.NoteTypeID = nt.GUID
	WHERE RefGUID = aGUID
UNION
	SELECT 2 AS S, n.GUID AS GUID,
		nt.Seq AS Seq,
		JoinStrings(nt.Name, n.NameType) As Type,
		n.Name AS Value
	FROM Names n
	LEFT JOIN NameTypes nt on n.NameTypeID = nt.GUID
	WHERE RefGUID = aGUID
UNION
	SELECT 3 AS S, i.GUID AS GUID,
		it.Seq AS Seq,
		JoinStrings(it.Name, i.IdentifierType) As Type,
		i.Identifier AS Value
	FROM Identifiers i
	LEFT JOIN IdentifierTypes it on i.IdentifierTypeID = it.GUID
	WHERE RefGUID = aGUID
UNION
	SELECT 4 AS S, e.GUID AS GUID,
		et.Seq AS Seq,
		JoinStrings(et.Name, e.EventType) As Type,
		e.Event AS Value
	FROM Events e
	LEFT JOIN EventTypes et on e.EventTypeID = et.GUID
	WHERE RefGUID = aGUID
	ORDER BY 1, 3, 4;
END
//


DELIMITER //
DROP FUNCTION IF EXISTS GetCategory
//
CREATE FUNCTION GetCategory (aCategoryETID INT, aCategoryValueID CHAR(36))
RETURNS VARCHAR(200)
	COMMENT 'Get the category text for a specific CategoryID'
BEGIN

	SET @Name = '';

	IF aCategoryETID = 145 THEN -- Subjects
		SELECT Name INTO @Name
		FROM Subjects
		WHERE GUID = aCategoryValueID;
        
	ELSEIF aCategoryETID = 115 THEN -- NamedEvents
		SELECT Name INTO @Name
		FROM NamedEvents
		WHERE GUID = aCategoryValueID;
    
	ELSEIF aCategoryETID = 107 THEN -- NamedPlaces
		SELECT Name INTO @Name
		FROM NamedPlaces
		WHERE GUID = aCategoryValueID;
    
	ELSEIF aCategoryETID = 125 THEN -- PerOrgs
		SELECT Name INTO @Name
		FROM PerOrgs
		WHERE GUID = aCategoryValueID;
    
	ELSEIF aCategoryETID = 155 THEN -- CurriculumElements
		SELECT Name INTO @Name
		FROM CurriculumElements
		WHERE GUID = aCategoryValueID;
        
	ELSEIF aCategoryETID = 531 THEN -- ItemTypes
		SELECT Name INTO @Name
		FROM ItemTypes
		WHERE GUID = aCategoryValueID;

    END IF;

    RETURN @Name;

END
//


DELIMITER //
DROP FUNCTION IF EXISTS GetCategoryETID
//
CREATE FUNCTION GetCategoryETID (aCategoryETID INT, aCategoryValueID CHAR(36))
RETURNS INT
	COMMENT 'Get the category ETID for a CategoryID - may be from many tables'
BEGIN

	SET @Name = '';

	IF aCategoryETID = 145 THEN -- Subjects
		SELECT Name INTO @Name
		FROM Subjects
		WHERE GUID = aCategoryValueID;
        
	ELSEIF aCategoryETID = 115 THEN -- NamedEvents
		SELECT Name INTO @Name
		FROM NamedEvents
		WHERE GUID = aCategoryValueID;
    
	ELSEIF aCategoryETID = 107 THEN -- NamedPlaces
		SELECT Name INTO @Name
		FROM NamedPlaces
		WHERE GUID = aCategoryValueID;
    
	ELSEIF aCategoryETID = 125 THEN -- PerOrgs
		SELECT Name INTO @Name
		FROM PerOrgs
		WHERE GUID = aCategoryValueID;
    
	ELSEIF aCategoryETID = 155 THEN -- CurriculumElements
		SELECT Name INTO @Name
		FROM CurriculumElements
		WHERE GUID = aCategoryValueID;
        
	ELSEIF aCategoryETID = 531 THEN -- ItemTypes
		SELECT Name INTO @Name
		FROM ItemTypes
		WHERE GUID = aCategoryValueID;

    END IF;

    RETURN @Name;

END
//



DELIMITER //
DROP PROCEDURE ChenhallDetails
//
DELIMITER //
CREATE PROCEDURE ChenhallDetails (aID INT, aUserID CHAR(36))
COMMENT 'Extract all ancestors and all children for an item in the ChenhallNomenclature table'
BEGIN
	
    CREATE TEMPORARY TABLE IF NOT EXISTS Ancestors (
		Level INT,
        ID INT,
        Name VARCHAR(200),
        RecordType VARCHAR(50)
    );
    
    DELETE FROM Ancestors;
    
    INSERT INTO Ancestors VALUES (0, 0, 'All Categories', '');
    
    SELECT ParentID INTO @ID
    FROM ChenhallNomenclature
    WHERE ID = aID;
    
    WHILE @ID IS NOT NULL DO
    
		INSERT INTO Ancestors
        SELECT Level, ID, Name, RecordType
        FROM ChenhallNomenclature WHERE ID = @ID;

		SELECT ParentID INTO @ParentID
		FROM ChenhallNomenclature
		WHERE ID = @ID;

        SET @ID = @ParentID;

	END WHILE;

	-- ancestors
	SELECT Level, ID, Name, RecordType,
   		IsUserFavourite(ID, aUserID) AS Star
    FROM Ancestors
    ORDER BY 1;

	-- current term
    
	SELECT ID, Name, Definition, NonPreferredTerm, Notes, Image_URL, 
		OtherDesigParks, DoNotConfuseWith, RecordType,
		IsUserFavourite(aID, aUserID) AS Star
	FROM ChenhallNomenclature
    WHERE ID = aID;
        
	-- children
    SELECT Level, ID, Name, RecordType,
		IsUserFavourite(ID, aUserID) AS Star
    FROM CHenhallNomenclature
    WHERE (aID <> 0 AND ParentID = aID)
    OR (aID = 0 AND ParentID IS NULL);
    
    DROP TEMPORARY TABLE Ancestors;
    
END
//


DELIMITER //
DROP PROCEDURE GenCategories
//
DELIMITER //
CREATE PROCEDURE GenCategories (aGUID CHAR(36), aUserGUID CHAR(36))
COMMENT 'Extract all entities which link to this category '
BEGIN
	
	SELECT
		e.EntityName AS Class,
		JoinStrings(c.CategoryValue, c.CategoryValueExt) AS `Category`,
        c.CategoryValueID AS CategoryValueID,
        DateDescription,
        Location,
        Priority,
        IsUserFavourite(u.guid, c.GUID) AS Star
    FROM Categorizations c
    CROSS JOIN Users u
    LEFT JOIN EntityTypes e ON c.CategoryETID = e.ETID
    WHERE c.CategoryValueID = aGUID
    AND u.GUID = aUserGUID
    ORDER BY 1, 2;
END
//

Use onemuseum;

DELIMITER //
DROP PROCEDURE GetEntitiesFromCategory
//
DELIMITER //
CREATE PROCEDURE GetEntitiesFromCategory (aGUID CHAR(36), aUserGUID CHAR(36))
COMMENT 'Extract all entities which link to this category '
BEGIN
	SELECT e.GUID, e.ETName, e.EntityName,
		e.Museum, c.CategoryValue, c.CategoryValueExt,
		IsUserFavourite(aGUID, aUserGUID) AS Star
	FROM EntityNames e
	JOIN Categorizations c ON c.RefGUID = e.GUID
	WHERE CategoryValueID = aGUID;
END
//

/*
CALL GetEntitiesFromCategory ('C1BDE79A-5D1D-1D1E-1DF5-CF640589655D', 'D3C661FA-6E5D-430D-B4CD-7B7C7BFDB764')

	SELECT e.GUID, e.ETName, e.EntityName,
		e.Museum, c.CategoryValue, c.CategoryValueExt,
		IsUserFavourite('C1BDE79A-5D1D-1D1E-1DF5-CF640589655D', 'D3C661FA-6E5D-430D-B4CD-7B7C7BFDB764') AS Star
	FROM EntityNames e
	JOIN Categorizations c ON c.RefGUID = e.GUID
	WHERE e.GUID = '7229963C-7DEE-FFFF-FE94-8C6CAD256CDC';
    
    SELECT *
    FROM 
*/

/*

USE OneMuseum;

SELECT * FROM ChenhallNomenclature WHERE Image_URL IS NOT NULL LIMIT 10;

CALL GenDetails('namedevent', 'BD9E5F86-9491-451F-871F-845B56486ED0', 'D3C661FA-6E5D-430D-B4CD-7B7C7BFDB764')

SELECT * FROM CHenhallNomenclature LIMIT 200;

CALL ChenhallDetails (0, 'D3C661FA-6E5D-430D-B4CD-7B7C7BFDB764');

CALL GenCategories('EAA5E41A-5180-46D3-95A4-C33693E61063')


	SET @SQL = CONCAT('SELECT * FROM ', 'namedevent', 'Details WHERE GUID = ? AND UserID = ?');
	PREPARE st1 FROM @SQL;
    -- must put into local variable - does not work with arguments directly
	SET @GUID = 'BD9E5F86-9491-451F-871F-845B56486ED0';
    SET @UserID = 'D3C661FA-6E5D-430D-B4CD-7B7C7BFDB764';
    EXECUTE st1 USING @GUID, @UserID;
	DEALLOCATE PREPARE st1;

SELECT * FROM NamedEventDetails WHERE Name LIKE '2004%' AND UserID = 'D3C661FA-6E5D-430D-B4CD-7B7C7BFDB764'

	SELECT
		e.EntityName AS Category,
		JoinStrings(c.CategoryValue, c.CategoryValueExt) AS `Value`,
        DateDescription,
        Location,
        Priority		
    FROM Categorizations c
    LEFT JOIN EntityTypes e ON c.CategoryETID = e.ETID
    WHERE RefGUID = '3F26C4F3-2C0F-493C-B235-40AED60D0F07';

SELECT * FROM Categorizations;

CALL GetCommonData ('3F26C4F3-2C0F-493C-B235-40AED60D0F07');

USE OneMuseum;

	SELECT *
    FROM Categorizations c
    LEFT JOIN EntityTypes e ON c.CategoryETID = e.ETID
    WHERE RefGUID = '3F26C4F3-2C0F-493C-B235-40AED60D0F07';
    


CALL GetCategories ('3F26C4F3-2C0F-493C-B235-40AED60D0F07');

SET @EntityGUID = '3F26C4F3-2C0F-493C-B235-40AED60D0F07';
SET @TableName = 'Museums';
	SET @SQL = CONCAT('SELECT * FROM ', @TableName, ' WHERE GUID = ?');
	PREPARE st1 FROM (@SQL);
    EXECUTE st1 USING @EntityGUID;
	DEALLOCATE PREPARE st1;

SELECT * FROM Identifiers

-- TEST SNIPPETS
SELECT JoinStrings('abs', 'abs')


SELECT * FROM Stories;
SELECT * FROM Museums;

SELECT * FROM Users;
SELECT * FROM EntityNames;

CALL UserEntityFavourite ('D3C661FA-6E5D-430D-B4CD-7B7C7BFDB764', 'A99E4CDA-0DDB-4237-84BC-C38507EB754E')

SELECT IsUserFavourite ('D3C661FA-6E5D-430D-B4CD-7B7C7BFDB764', 'A99E4CDA-0DDB-4237-84BC-C38507EB754E') As Star

SELECT * FROM UserEntities

    SELECT c.GUID as guid, m.Name as Museum,
        c.Name as Collection, ct.Name as Type,
        CASE WHEN EXISTS(
            SELECT * FROM UserEntities
            WHERE UserID ='D3C661FA-6E5D-430D-B4CD-7B7C7BFDB764'
            AND RefGUID = c.GUID) THEN 1 ELSE 0 END AS Star
    FROM Collections c
    LEFT JOIN CollectionTypes ct ON c.CollectionTypeID = ct.GUID
    LEFT JOIN Museums m on c.MuseumID = m.GUID
    
SELECT m.GUID as guid,
 CASE WHEN EXISTS (
	SELECT * FROM UserEntities
    WHERE UserID = 'D3C661FA-6E5D-430D-B4CD-7B7C7BFDB764' AND RefGUID = m.GUID)
 THEN 1 ELSE 0 END AS Star, 
 m.Name As Museum,     c.Name AS Country, m.CountryID,     mp.Name AS Parent, 
 mt.Name AS Type, m.MuseumTypeID
 FROM Museums m
 LEFT JOIN Museums mp ON m.ParentID = mp.GUID
 LEFT JOIN MuseumTypes mt ON m.MuseumTypeID = mt.GUID
 LEFT JOIN Countries c ON m.CountryID = c.GUID 
 WHERE
 m.name LIKE '%%' OR mp.Name LIKE '%%' OR c.Name LIKE '%' ORDER BY m.Name
 LIMIT :l OFFSET :o


SET @res = OneMuseum.IsUserFavourite('D3C661FA-6E5D-430D-B4CD-7B7C7BFDB764', '3F26C4F3-2C0F-493C-B235-40AED60D0F07')

SELECT * FROM UserEntities
*/