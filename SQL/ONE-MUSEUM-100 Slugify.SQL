/*
ONE-MUSEUM-100 : Fix friendly URLs usig Slugs

1 - slugiy function
2 - Add Slug field for key tables and add UNIQUE index
3 - 

*/

DELIMITER ;
CREATE TABLE _DEBUG
(
	ID SERIAL,
	item varchar(20),
    item_value varchar(1000)
);

DELIMITER //
CREATE PROCEDURE _DEBUG_ADD (aItem varchar(20), aItemValue varchar(10000))
BEGIN
	INSERT INTO _Debug (item, item_value)
    VALUES (aItem, aItemValue);
END//

-- -----------------------------------------------------------------
-- 1 : Add a slugify functions
-- -----------------------------------------------------------------

DELIMITER ;
DROP FUNCTION IF EXISTS `slugify`;

DELIMITER //
CREATE DEFINER=`root`@`localhost`
FUNCTION `slugify`(aStr varchar(200))
RETURNS varchar(200) CHARSET latin1
DETERMINISTIC

BEGIN
-- https://stackoverflow.com/questions/5409831/mysql-stored-function-to-create-a-slug

    DECLARE x, y, z INT;
    DECLARE tStr VARCHAR(200);
    DECLARE is_allowed BOOL;
    DECLARE c, check_char VARCHAR(1);

    SET tStr = LOWER(aStr);
		-- INSERT INTO _DEBUG (item, item_value) VALUES ('NAME 1', tStr);

    SET tStr = REPLACE(tStr, '&', ' and ');
		-- INSERT INTO _DEBUG (item, item_value) VALUES ('NAME 2', tStr);

    SELECT tStr REGEXP('[^a-z0-9\-]+') INTO x;
    IF x = 1 THEN
        SET z = 1;
        WHILE z <= Char_length(tStr) DO
            SET c = SUBSTRING(tStr, z, 1);
            -- INSERT INTO _DEBUG (item, item_value) VALUES (CONCAT('CHAR ', z), CONCAT(c, ' ', ASCII(c)));
            SET is_allowed = FALSE;
            IF !((ASCII(c) = 45) OR (ASCII(c) >= 48 AND ASCII(c) <= 57) OR (ASCII(c) >= 97 AND ASCII(c) <= 122)) THEN
                SET tStr = REPLACE(tStr, c, '-');
            END IF;
            SET z = z + 1;
        END WHILE;
    END IF;
		-- INSERT INTO _DEBUG (item, item_value) VALUES ('NAME 3', tStr);

    SELECT tStr REGEXP("^-|-$|'") INTO x;
    IF x = 1 THEN
        SET tStr = REPLACE(tStr, "'", '');
        SET z = Char_length(tStr);
        SET y = Char_length(tStr);
        Dash_check: WHILE z > 1 DO
            IF Strcmp(SUBSTRING(tStr, -1, 1), '-') = 0 THEN
                SET tStr = SUBSTRING(tStr,1, y-1);
                SET y = y - 1;
            Else
                LEAVE Dash_check;
            END IF;
            SET z = z - 1;
        END WHILE;
    END IF;
        -- INSERT INTO _DEBUG (item, item_value) VALUES ('NAME 4', tStr);

    REPEAT
        SELECT tStr REGEXP("--") INTO x;
        IF x = 1 THEN
            SET tStr = REPLACE(tStr, "--", "-");
        END IF;
    UNTIL x <> 1 END REPEAT;
        -- INSERT INTO _DEBUG (item, item_value) VALUES ('NAME 5', tStr);

    IF LOCATE('-', tStr) = 1 THEN
        SET tStr = SUBSTRING(tStr, 2);
    END IF;
    
    RETURN tStr;
END;
//

DELIMITER ;

-- -----------------------------------------------------------------
-- 2 : Add Slug fields to each of the data tables which will be used for friendly URLs
-- create UNIQUE indexes foe the slug field
-- -----------------------------------------------------------------

-- LESSONS


ALTER TABLE Lessons
ADD Slug varchar(255) AFTER ID;
CREATE UNIQUE INDEX IN_Lessons_slug ON Lessons (Slug);

-- MUSEUMS

ALTER TABLE Museums
ADD Slug varchar(255) NULL AFTER ID;
CREATE UNIQUE INDEX IN_Museums_slug ON Museums (Slug);

-- COLLECTIONS

ALTER TABLE Collections
ADD Slug varchar(255) NULL AFTER ID;
CREATE UNIQUE INDEX IN_Collections_slug ON Collections (Slug);


-- ITEMS

ALTER TABLE Items
ADD Slug varchar(255) NULL AFTER ID;
CREATE UNIQUE INDEX IN_Items_slug ON Items (Slug);
    
    
-- BIOGRAPHIES

ALTER TABLE Biographies
ADD Slug varchar(255) NULL AFTER ID;
CREATE UNIQUE INDEX IN_Biographies_slug ON Biographies (Slug);


-- CURRICULUMELEMENTS

ALTER TABLE CurriculumElements
ADD Slug varchar(255) NULL AFTER ID;
CREATE UNIQUE INDEX IN_CurriculumElements_slug ON CurriculumElements (Slug);


-- EXHIBITIONS

ALTER TABLE Exhibitions
ADD Slug varchar(255) NULL AFTER ID;
CREATE UNIQUE INDEX IN_Exhibitions_slug ON Exhibitions (Slug);


-- EXPERTS

ALTER TABLE Experts
ADD Slug varchar(255) NULL AFTER ID;
CREATE UNIQUE INDEX IN_Experts_slug ON Experts (Slug);


-- NAMED PLACES

ALTER TABLE NamedPlaces
ADD Slug varchar(255) NULL AFTER ID;
CREATE UNIQUE INDEX IN_NamedPlaces_slug ON NamedPlaces (Slug);

    
-- NAMED EVENTS

ALTER TABLE NamedEvents
ADD Slug varchar(255) NULL AFTER ID;
CREATE UNIQUE INDEX IN_NamedEvents_slug ON NamedEvents (Slug);


-- PUBLICATIONS

ALTER TABLE Publications
ADD Slug varchar(255) NULL AFTER ID;
CREATE UNIQUE INDEX IN_Publications_slug ON Publications (Slug);


-- STORIES

ALTER TABLE Stories
ADD Slug varchar(255) NULL AFTER ID;
CREATE UNIQUE INDEX IN_Stories_slug ON Stories (Slug);

DELIMITER ;
DROP TRIGGER IF EXISTS TR_stories_insert;
DROP TRIGGER IF EXISTS TR_stories_update;
    

-- -----------------------------------------------------------------
-- 3 : Slugify procedures by type of content
-- -----------------------------------------------------------------

DELIMITER ;
DROP PROCEDURE IF EXISTS `slugify_lesson`;
DELIMITER //
CREATE DEFINER=`root`@`localhost`
PROCEDURE `slugify_lesson`(aGUID CHAR(36))
BEGIN
	SET @GUID = aGUID;
	START TRANSACTION;
    SELECT LEFT(Name, 200) INTO @Name FROM Lessons  WHERE GUID = @GUID;
    SET @Slug = slugify(@Name);
	SELECT COUNT(*) INTO @Count FROM Lessons WHERE Slug LIKE CONCAT(@Slug, '%') AND GUID <> @GUID;  
	UPDATE Lessons SET Slug = 
		CASE WHEN @Count = 0 THEN @Slug
        ELSE CONCAT(@Slug,'-', @Count+1) END
	WHERE GUID = @GUID;
	COMMIT;
END
//


DELIMITER ;
DROP PROCEDURE IF EXISTS `slugify_museum`;
DELIMITER //
CREATE DEFINER=`root`@`localhost`
PROCEDURE `slugify_museum`(aGUID CHAR(36))
BEGIN
	SET @GUID = aGUID;
	START TRANSACTION;
    SELECT LEFT(Name, 200) INTO @Name FROM Museums  WHERE GUID = @GUID;
    SET @Slug = slugify(@Name);
	SELECT COUNT(*) INTO @Count FROM Museums WHERE Slug LIKE CONCAT(@Slug, '%') AND GUID <> @GUID;  
	UPDATE Museums SET Slug = 
		CASE WHEN @Count = 0 THEN @Slug
        ELSE CONCAT(@Slug,'-', @Count+1) END
	WHERE GUID = @GUID;
	COMMIT;
END
//


-- COLLECTION 

DELIMITER ;
DROP PROCEDURE IF EXISTS `slugify_collection`;
DELIMITER //
CREATE DEFINER=`root`@`localhost`
PROCEDURE `slugify_collection`(aGUID CHAR(36))
BEGIN
	SET @GUID = aGUID;
	-- TART TRANSACTION;
    SELECT LEFT(Name, 200) INTO @Name FROM Collections WHERE GUID = @GUID;
    SET @Slug = slugify(@Name);
	SELECT COUNT(*) INTO @Count FROM Collections WHERE Slug LIKE CONCAT(@Slug, '%') AND GUID <> @GUID;  
	UPDATE Collections SET Slug = 
		CASE WHEN @Count = 0 THEN @Slug
        ELSE CONCAT(@Slug,'-', @Count+1) END
	WHERE GUID = @GUID;
	-- COMMIT;
END
//


-- ITEM

DELIMITER ;
DROP PROCEDURE IF EXISTS `slugify_item`;
DELIMITER //
CREATE DEFINER=`root`@`localhost`
PROCEDURE `slugify_item`(aGUID CHAR(36))
BEGIN
	SET @GUID = aGUID;
	START TRANSACTION;
    SELECT LEFT(Name, 200) INTO @Name FROM Items WHERE GUID = @GUID;
    SET @Slug = slugify(@Name);
	SELECT COUNT(*) INTO @Count FROM Items WHERE Slug LIKE CONCAT(@Slug, '%') AND GUID <> @GUID;  
	UPDATE Items SET Slug = 
		CASE WHEN @Count = 0 THEN @Slug
        ELSE CONCAT(@Slug,'-', @Count+1) END
	WHERE GUID = @GUID;
	COMMIT;
END
//


-- BIOGRAPHY

DELIMITER ;
DROP PROCEDURE IF EXISTS `slugify_biography`;
DELIMITER //
CREATE DEFINER=`root`@`localhost`
PROCEDURE `slugify_biography`(aGUID CHAR(36))
BEGIN
	SET @GUID = aGUID;
	START TRANSACTION;
    SELECT LEFT(Name, 200) INTO @Name FROM Biographies WHERE GUID = @GUID;
    SET @Slug = slugify(@Name);
	SELECT COUNT(*) INTO @Count FROM Biographies WHERE Slug LIKE CONCAT(@Slug, '%') AND GUID <> @GUID;  
	UPDATE Biographies SET Slug = 
		CASE WHEN @Count = 0 THEN @Slug
        ELSE CONCAT(@Slug,'-', @Count+1) END
	WHERE GUID = @GUID;
	COMMIT;
END
//


-- CURRICULUM ELEMENTS

-- use the curriculum, subject and element name as the basis for the slug

DELIMITER ;
DROP PROCEDURE IF EXISTS `slugify_curriculumelement`;
DELIMITER //
CREATE DEFINER=`root`@`localhost`
PROCEDURE `slugify_curriculumelement`(aGUID CHAR(36))
BEGIN
	SET @GUID = aGUID;
	START TRANSACTION;
    SELECT LEFT(CONCAT(c.Code, ' ', cs.Name, ' ', ce.Name), 200) INTO @Name
		FROM CurriculumElements ce
        LEFT JOIN Curricula c ON ce.CurriculumID = c.GUID
        LEFT JOIN CurriculumSubjects cs ON ce.CurriculumSubjectID = cs.GUID
        WHERE ce.GUID = @GUID;
    SET @Slug = slugify(@Name);
	SELECT COUNT(*) INTO @Count FROM CurriculumElements WHERE Slug LIKE CONCAT(@Slug, '%') AND GUID <> @GUID;  
	UPDATE CurriculumElements SET Slug = 
		CASE WHEN @Count = 0 THEN @Slug
        ELSE CONCAT(@Slug,'-', @Count+1) END
	WHERE GUID = @GUID;
	COMMIT;
END
//

DELIMITER ;
DROP PROCEDURE IF EXISTS `slugify_exhibition`;
DELIMITER //
CREATE DEFINER=`root`@`localhost`
PROCEDURE `slugify_exhibition`(aGUID CHAR(36))
BEGIN
	SET @GUID = aGUID;
	START TRANSACTION;
    SELECT LEFT(Name, 200) INTO @Name FROM Exhibitions WHERE GUID = @GUID;
    SET @Slug = slugify(@Name);
	SELECT COUNT(*) INTO @Count FROM Exhibitions WHERE Slug LIKE CONCAT(@Slug, '%') AND GUID <> @GUID;  
	UPDATE Exhibitions SET Slug = 
		CASE WHEN @Count = 0 THEN @Slug
        ELSE CONCAT(@Slug,'-', @Count+1) END
	WHERE GUID = @GUID;
	COMMIT;
END
//


DELIMITER ;
DROP PROCEDURE IF EXISTS `slugify_expert`;
DELIMITER //
CREATE DEFINER=`root`@`localhost`
PROCEDURE `slugify_expert`(aGUID CHAR(36))
BEGIN
	SET @GUID = aGUID;
	START TRANSACTION;
    SELECT LEFT(PerOrg, 200) INTO @Name FROM Experts WHERE GUID = @GUID;
    SET @Slug = slugify(@Name);
	SELECT COUNT(*) INTO @Count FROM Experts WHERE Slug LIKE CONCAT(@Slug, '%') AND GUID <> @GUID;  
	UPDATE Experts SET Slug = 
		CASE WHEN @Count = 0 THEN @Slug
        ELSE CONCAT(@Slug,'-', @Count+1) END
	WHERE GUID = @GUID;
	COMMIT;
END
//


DELIMITER ;
DROP PROCEDURE IF EXISTS `slugify_namedplace`;
DELIMITER //
CREATE DEFINER=`root`@`localhost`
PROCEDURE `slugify_namedplace`(aGUID CHAR(36))
BEGIN
	SET @GUID = aGUID;
	START TRANSACTION;
    SELECT LEFT(Name, 200) INTO @Name FROM NamedPlaces WHERE GUID = @GUID;
    SET @Slug = slugify(@Name);
	SELECT COUNT(*) INTO @Count FROM NamedPlaces WHERE Slug LIKE CONCAT(@Slug, '%') AND GUID <> @GUID;  
	UPDATE NamedPlaces SET Slug = 
		CASE WHEN @Count = 0 THEN @Slug
        ELSE CONCAT(@Slug,'-', @Count+1) END
	WHERE GUID = @GUID;
	COMMIT;
END
//


DELIMITER ;
DROP PROCEDURE IF EXISTS `slugify_namedevent`;
DELIMITER //
CREATE DEFINER=`root`@`localhost`
PROCEDURE `slugify_namedevent`(aGUID CHAR(36))
BEGIN
	SET @GUID = aGUID;
	START TRANSACTION;
    SELECT LEFT(Name, 200) INTO @Name FROM NamedEvents WHERE GUID = @GUID;
    SET @Slug = slugify(@Name);
	SELECT COUNT(*) INTO @Count FROM NamedEvents WHERE Slug LIKE CONCAT(@Slug, '%') AND GUID <> @GUID;  
	UPDATE NamedEvents SET Slug = 
		CASE WHEN @Count = 0 THEN @Slug
        ELSE CONCAT(@Slug,'-', @Count+1) END
	WHERE GUID = @GUID;
	COMMIT;
END
//

-- PUBLICATION

DELIMITER ;
DROP PROCEDURE IF EXISTS `slugify_publication`;
DELIMITER //
CREATE DEFINER=`root`@`localhost`
PROCEDURE `slugify_publication`(aGUID CHAR(36))
BEGIN
	SET @GUID = aGUID;
	START TRANSACTION;
    SELECT LEFT(Name, 200) INTO @Name FROM Publications WHERE GUID = @GUID;
    SET @Slug = slugify(@Name);
	SELECT COUNT(*) INTO @Count FROM Publications WHERE Slug LIKE CONCAT(@Slug, '%') AND GUID <> @GUID;  
	UPDATE Publications SET Slug = 
		CASE WHEN @Count = 0 THEN @Slug
        ELSE CONCAT(@Slug,'-', @Count+1) END
	WHERE GUID = @GUID;
	COMMIT;
END
//

-- STORY

DELIMITER ;
DROP PROCEDURE IF EXISTS `slugify_story`;
DELIMITER //
CREATE DEFINER=`root`@`localhost`
PROCEDURE `slugify_story`(aGUID CHAR(36))
BEGIN
	SET @GUID = aGUID;
	START TRANSACTION;
    SELECT LEFT(Name, 200) INTO @Name FROM Stories WHERE GUID = @GUID;
    SET @Slug = slugify(@Name);
	SELECT COUNT(*) INTO @Count FROM Stories WHERE Slug LIKE CONCAT(@Slug, '%') AND GUID <> @GUID;  
	UPDATE Stories SET Slug = 
		CASE WHEN @Count = 0 THEN @Slug
        ELSE CONCAT(@Slug,'-', @Count+1) END
	WHERE GUID = @GUID;
	COMMIT;
END
//



-- THIS IS NOT AS YET WORKING - a GENERIC APPRPOACH FOR ALL TABLES 
-- CANNOT PUT A PREPARE INTO A PROCEDURE IN THIS WAY - LIMITATION OF MARIADB/MYSQL
/*
DELIMITER ;
DROP PROCEDURE IF EXISTS `slugify_row`;
DELIMITER //
CREATE DEFINER=`root`@`localhost`
PROCEDURE `slugify_row`(aTable VARCHAR(200), aGUID CHAR(36))
BEGIN

	SET @GUID = aGUID;
    

    SET @SQL = '
    SELECT LEFT(Name, 200) INTO @Name FROM $$TABLE$$ WHERE GUID = @GUID;
    SET @Slug = slugify(@Name);

	SELECT COUNT(*) INTO @Count FROM $$TABLE$$ WHERE Slug LIKE CONCAT(@Slug, \'%\') AND GUID <> @GUID; 
	UPDATE $$TABLE$$ SET Slug = 
		CASE WHEN @Count = 0 THEN @Slug
        ELSE CONCAT(@Slug,\'-\', @Count+1) END
	WHERE GUID = @GUID;';
    
    CALL _DEBUG_ADD ('SQL', @SQL);
    
    SET @SQL = REPLACE(@SQL, '$$TABLE$$', aTable);
    
    CALL _DEBUG_ADD ('SQL', @SQL);
    
	-- START TRANSACTION;
    PREPARE stat FROM @SQL;
    EXECUTE stat;
	-- COMMIT;
END
//
*/

-- -----------------------------------------------------------------
-- 4 : Set up slugs for all existing content
-- -----------------------------------------------------------------
-- if no duplicates can use an UPDATE
-- if there are duplicates must run as a CURSOR

-- LESSONS

DELIMITER //
CREATE PROCEDURE slugify_lessons ()
BEGIN
	DECLARE finished INTEGER DEFAULT 0;
	DECLARE tGUID varchar(100);

	DECLARE cur CURSOR FOR SELECT GUID FROM Lessons;
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET finished = 1;
	OPEN cur;
	getNext: LOOP
		FETCH cur INTO tGUID;
		IF finished = 1 THEN  LEAVE getNext; END IF;
        CALL slugify_lesson (tGUID);
	END LOOP getNext;
	CLOSE cur;
END
//
CALL slugify_lessons();


-- MUSEUMS

UPDATE Museums SET Slug = slugify(Name);

-- COLLECTIONS

DELIMITER //
CREATE PROCEDURE slugify_collections ()
BEGIN
	DECLARE finished INTEGER DEFAULT 0;
	DECLARE tGUID varchar(100) DEFAULT "";

	DECLARE cur CURSOR FOR SELECT GUID FROM Collections;
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET finished = 1;
	OPEN cur;
	getNext: LOOP
		FETCH cur INTO tGUID;
		IF finished = 1 THEN  LEAVE getNext; END IF;
        CALL slugify_collection (tGUID);
	END LOOP getNext;
	CLOSE cur;
END
//

CALL slugify_collections();

-- ITEMS

UPDATE Items SET Slug = slugify(Name);

-- BIOGRAPHIES

UPDATE Biographies SET Slug = slugify(Name);

-- CURRICULUMELEMENTS

DELIMITER ;
DROP PROCEDURE IF EXISTS `slugify_curriculumelements`;
DELIMITER //
CREATE PROCEDURE slugify_curriculumelements ()
BEGIN
	DECLARE finished INTEGER DEFAULT 0;
	DECLARE tGUID varchar(100) DEFAULT "";

	DECLARE cur CURSOR FOR SELECT GUID FROM CurriculumElements;
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET finished = 1;
	OPEN cur;
	getNext: LOOP
		FETCH cur INTO tGUID;
		IF finished = 1 THEN  LEAVE getNext; END IF;
        CALL slugify_curriculumelement (tGUID);
	END LOOP getNext;
	CLOSE cur;
END
//
CALL slugify_curriculumelements();

-- EXPERTS

UPDATE Experts SET Slug = slugify(PerOrg) WHERE GUID = 'DF3EEA75-E637-4B79-82E8-C11957D0AB96';

SELECT * FROM Experts;

REPAIR TABLE Experts;

SHOW FULL PROCESSLIST 

KILL 469

SELECT  NAME_CONST('temp_string',NULL) REGEXP("--") INTO x

SELECT *
FROM INFORMATION_SCHEMA.STATISTICS
WHERE TABLE_SCHEMA = 'Experts';


SELECT * FROM CUrriculumElements;


CALL slugify_row ('Lessons', '');

DELIMITER ;

SELECT Name, Slug FROM Lessons ORDER BY 1;


DELIMITER ;



UPDATE Lessons SET Name = 'Quadratic expressions and equations' WHERE GUID = 'A6BAE1B4-4A73-C27F-881C-A16CAFD66DF5';


DELETE FROM _DEBUG;
CALL slugify_row ('Lessons', 'C1BDE79A-5D1D-1D1E-1DF5-CF640589655D');
CALL slugify_row ('Lessons', 'A6BAE1B4-4A73-C27F-881C-A16CAFD66DF5');
SELECT * FROM Lessons;
SELECT * FROM _DEBUG;



UPDATE Lessons SET Slug = null;
CALL slugify_lesson ('C1BDE79A-5D1D-1D1E-1DF5-CF640589655D');
CALL slugify_lesson ('A6BAE1B4-4A73-C27F-881C-A16CAFD66DF5');
SELECT * FROM Lessons;


UPDATE Lessons SET Slug = null;
CALL slugify_row ('Lessons', 'C1BDE79A-5D1D-1D1E-1DF5-CF640589655D');
CALL slugify_row ('Lessons', 'A6BAE1B4-4A73-C27F-881C-A16CAFD66DF5');
SELECT * FROM Lessons;
SELECT * FROM _DEBUG;

    SET @GUID = 'C1BDE79A-5D1D-1D1E-1DF5-CF640589655D';
    SET @Name = 'Queatric asd asd ';
	PREPARE stmt FROM '
    SELECT LEFT(Name, 200) INTO @Name FROM Lessons WHERE GUID = @GUID;
    SET @Slug = slugify(@Name);

	SELECT COUNT(*) INTO @Count FROM Lessons WHERE Slug LIKE CONCAT(@Slug, \'%\') AND GUID <> @GUID; 
	UPDATE Lessons SET Slug = 
		CASE WHEN @Count = 0 THEN @Slug
        ELSE CONCAT(@Slug,\'-\', @Count+1) END
	WHERE GUID = @GUID;';
SELECT * FROM MUseums;

FLUSH TABLES;


INSERT INTO Lessons (GUID, Name, MuseumID)
VALUES ('FF36E876-967D-4E9F-A8E8-A32610F77587', 'this is a new name', '3F26C4F3-2C0F-493C-B235-40AED60D0F07');

SELECT * FROM Lessons;



SELECT * FROM COllections;

CALL slugify_collection('EDA788B2-8F01-4515-87B2-AC3A29A1B644');


    SELECT LEFT(Name, 200) INTO @Name FROM Collections WHERE GUID = 'EDA788B2-8F01-4515-87B2-AC3A29A1B644';
    SET @Slug = slugify(@Name);
	SELECT COUNT(*) INTO @Count FROM Collections WHERE Slug LIKE CONCAT(@Slug, '%') AND GUID <> @GUID;  
	UPDATE Collections SET Slug = 
		CASE WHEN @Count > 0 THEN CONCAT(@Slug,'-', CAST(@Count+1 AS varchar(50)))
        ELSE @Slug END
	WHERE GUID = 'EDA788B2-8F01-4515-87B2-AC3A29A1B644';
    
    
   	UPDATE Collections SET Name = Name
	WHERE GUID = 'EDA788B2-8F01-4515-87B2-AC3A29A1B644';
    
SELECT @Name, @Slug, @Count;

SELECT CONCAT(@Slug,'-', @Count+1);




