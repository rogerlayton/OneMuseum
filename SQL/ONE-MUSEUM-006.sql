/*
** ONE-MUSEUM.COM
** SCRIPT: ONE-MUSEUM-006.SQL : CONTENT LOADER
** 
*/


DELIMITER //
DROP PROCEDURE IF EXISTS UPLOAD_TEST //
CREATE PROCEDURE UPLOAD_TEST (aValue INT)
BEGIN

	SELECT CONCAT('result is ', aValue) AS result;

END
//

CALL UPLOAD_TEST(123);


DELIMITER //
DROP PROCEDURE IF EXISTS UPLOAD_InputFile //
CREATE PROCEDURE UPLOAD_InputFile (
	aFileName VARCHAR(100),
    aMuseum VARCHAR(255),
    aUserID CHAR(36),
    aNumLines INT,
    aContent TEXT
)
COMMENT 'Create a new InputFile record and return the GUID.'
BEGIN

	DECLARE tUserID CHAR(36);
	DECLARE tMuseumID CHAR(36);
    DECLARE tNumErrors INT;
    DECLARE tError VARCHAR(255);
    
    DECLARE tID BIGINT;
    DECLARE tGUID CHAR(36);
    
    DECLARE tInputFileID BIGINT;
    DECLARE tInputFileGUID CHAR(36);
    
    DECLARE tCommandNum INT;
    
    DECLARE tStatus INT;
    DECLARE tCancel BIT;
    
    SET tNumErrors := 0;
    SET tError := NULL;
    SET tCommandNum := 90001;
    SET tStatus := 0;
    SET tCancel := 0;
    
    -- is this a valid user, without the user code we can do nothing
    
    SELECT SQL_CALC_FOUND_ROWS GUID INTO tUserID
    FROM Users WHERE GUID = aUserID;
    IF FOUND_ROWS() = 0 THEN
		SET tNumErrors := tNumErrors + 1;
        SET tError := CONCAT('User code "', aUserID, '" not found');
        SET tStatus := 9;
        SET tCancel = 1;
    END IF;
    
    -- does this museum exist?
    
    SELECT SQL_CALC_FOUND_ROWS GUID INTO tMuseumID
    FROM Museums
    WHERE Name = aMuseum OR Code = aMuseum;
    IF FOUND_ROWS() = 0 THEN
		SET tNumErrors := tNumErrors + 1;
        SET tError := CONCAT('Museum code/name "', aMuseum, '" not found');
        SET tStatus := 9;
    END IF;
    
    If tCancel = 0 THEN
		INSERT INTO InputFiles(FileName, MuseumID, Museum, UserID, NumLines, Content, NumErrors, Status)
		VALUES (aFileName, tMuseumID, aMuseum, aUserID, aNumLines, aContent, tNumErrors, tStatus);

		SET tInputFileID := LAST_INSERT_ID();
		
		SELECT GUID INTO tInputFileGUID
		FROM InputFiles
		WHERE ID = tInputFileID;
	END IF;    
    
    IF tError <> '' AND tCancel = 0 THEN
		CALL UPLOAD_InputFileLine (tInputFileGUID, 0, 0, tCommandNum, '_LOAD', 'U001', tError);
		SET tCommandNum := tCommandNum + 1;
		CALL UPLOAD_InputFileLine (tInputFileGUID, 0, 0, tCommandNum, '_EXIT', 'U999', 'Errors encountered: Canceled processing');
        
        UPDATE InputFiles
        SET	NumErrors = tNumErrors, Status = 9
        WHERE ID = tInputFileID;
    END IF;
    
    -- get unique batch number = tInputFileID
    
    SELECT
		tInputFileID AS ID, 
		tInputFileGUID AS GUID,
		tNumErrors AS ErrorCount,
        tError AS Error;

END
//


DELIMITER //
DROP PROCEDURE IF EXISTS UPLOAD_InputFileLine //
CREATE PROCEDURE UPLOAD_InputFileLine (
	aInputFileID CHAR(36),
    aLineStart INT,
    aLineEnd INT,
    aCommandNum INT,
    aCommand TEXT,
    aErrorCode VARCHAR(10),
    aError VARCHAR(255)
)
BEGIN

	INSERT INTO InputFileLines(InputFileID, LineStart, LineEnd, CommandNum, Command, ErrorCode, Error)
    VALUES (aINputFileID, aLineStart, aLineEnd, aCommandNum, aCommand, aErrorCode, aError);
    
    IF aErrorCode IS NOT NULL AND aErrorCode <> '' THEN
		UPDATE InputFiles
        SET NumErrors = NumErrors + 1,
			Status = 9
		WHERE GUID = aInputFileID;
    END IF;

END
//
	

DELIMITER //
DROP PROCEDURE IF EXISTS UPLOAD_Lesson //
CREATE PROCEDURE UPLOAD_Lesson (
	aMuseumID CHAR(36),
    aLessonType VARCHAR(100),
    aName VARCHAR(200),
    aDescription TEXT,
    aCurriculumCode CHAR(20),
    aCurriculumTopic CHAR(100),
    aContent TEXT,
    aKeywords VARCHAR(1000),
    aInputFileID CHAR(36)
)
BEGIN
-- Upload a lesson to One-Museum
-- if element code given this must also exist
-- name, description and content must not be empty
-- no check on validity of content
-- link to the INputFile which was used to create or to last update this

	DECLARE tInputFileID BIGINT;
    DECLARE tInputFileGUID CHAR(36);
    
	DECLARE tLessonID CHAR(36);
    DECLARE tLessonGUID CHAR(36);    
    DECLARE tLessonTypeID CHAR(36);
    
    DECLARE tCurriculumID CHAR(36);
    DECLARE tCurriculumSubjectID CHAR(36);
    DECLARE tCurriculumElementID CHAR(36);
    
    DECLARE tNumErrors INT;
    DECLARE tErrorCode VARCHAR(100);
	DECLARE tError VARCHAR(2000);    
    
    SET tCurriculumSubject := NULL;
    SET tCurriculumElementID := NULL;
    
    SET tNumErrors := 0;
	SET tErrorCode := '';
    SET tError :=  '';
    
    -- lookup LessonType but do not raise error if not found
    -- then keep as text and will have to be actioned later by the user after upload
    -- may require adding a new lesson type not in the vocabulary
    
    SELECT SQL_CALC_FOUND_ROWS GUID INTO tLessonTypeID
    FROM LessonTypes
    WHERE Name = aLessonType OR Code = aLessonType;
    IF FOUND_ROWS() = 0 THEN
		SET tLessonTypeID = NULL;
    END IF;
    
    -- curriculum subject - must be found
    
	SELECT SQL_CALC_FOUND_ROWS GUID INTO tCurriculumID
    FROM Curricula
    WHERE Code = aCurriculumCode;
    
    IF FOUND_ROWS() = 0 THEN
		SET tNumErrors := tNumErrors + 1;
        IF tErrorCode <> '' THEN
			SET tErrorCode := CONCAT(tErrorCode, '/');
            SET tError := CONCAT(tError, ';');
		END IF;
        SET tErrorCode := CONCAT(tErrorCode, 'U701');
        SET tError := CONCAT(tError, 'Curriculum code not found;');
    END IF;
    
    -- curriculum subject or element - ONE must be specified
    -- SUBJECT - general linkage to subject and not to topic
    -- ELEMENT - specific linkage to a coded topic in the curriculum
    
	SELECT SQL_CALC_FOUND_ROWS GUID INTO tCurriculumSubjectID
    FROM CurriculumSubjects
    WHERE (Code = aCurriculumTopic OR Name = aCurriculumTopic)
    AND (CurriculumID IS NULL OR CurriculumID = tCurriculumID);
    
    -- curriculum element 
    
	SELECT SQL_CALC_FOUND_ROWS GUID INTO tCurriculumElementID
	FROM CurriculumElements
	WHERE Code = aCurriculumTopic
	AND CurriculumID = tCurriculumID;
    
    -- check that one of subject or topic provided
    
	IF tCurriculumSubjectID IS NULL
    AND tCurriculumElementID IS NULL THEN
		SET tNumErrors := tNumErrors + 1;
		IF tErrorCode <> '' THEN
			SET tErrorCode := CONCAT(tErrorCode, '/');
			SET tError := CONCAT(tError, ';');
		END IF;
		SET tErrorCode := CONCAT(tErrorCode, 'U702');
		SET tError := CONCAT(tError, 'Curriculum topic not found as a subject code or name or element code');
	END IF;
    
    -- name must not be null
    
    IF aName IS NULL OR TRIM(aName) = '' THEN
		SET tNumErrors := tNumErrors + 1;
        IF tErrorCode <> '' THEN
			SET tErrorCode := CONCAT(tErrorCode, '/');
			SET tError := CONCAT(tError, ';');
		END IF;
		SET tErrorCode := CONCAT(tErrorCode, 'U704');
		SET tError := CONCAT(tError, 'Lesson name is missing or empty');
	END IF;
    
    -- description must not be null
    
    IF aDescription IS NULL OR TRIM(aDescription) = '' THEN
		SET tNumErrors := tNumErrors + 1;
        IF tErrorCode <> '' THEN
			SET tErrorCode := CONCAT(tErrorCode, '/');
			SET tError := CONCAT(tError, ';');
		END IF;
		SET tErrorCode := CONCAT(tErrorCode, 'U705');
		SET tError := CONCAT(tError, 'Lesson description is missing or empty');
	END IF;

    -- content must not be null
    
    IF aContent IS NULL OR TRIM(aContent) = '' THEN
		SET tNumErrors := tNumErrors + 1;
        IF tErrorCode <> '' THEN
			SET tErrorCode := CONCAT(tErrorCode, '/');
			SET tError := CONCAT(tError, ';');
		END IF;
		SET tErrorCode := CONCAT(tErrorCode, 'U706');
		SET tError := CONCAT(tError, 'Lesson content is missing or empty');
	END IF;
    
    IF tNumErrors = 0 THEN
    
		INSERT INTO Lessons(MuseumID, LessonTypeID, LessonType,
			CurriculumSubjectID, CurriculumElementID,
            Name, Description, Content, Keywords, InputFileID)
		VALUES (aMuseumID, tLessonTypeID, aLessonType,
			tCurriculumSubjectID, tCurriculumElementID,
            aName, aDescription, aContent, aKeywords, aInputFileID);
        
        SET tLessonID := LAST_INSERT_ID();
        SELECT GUID INTO tLessonGUID FROM Lessons WHERE ID = tLessonID;
        
	END IF;
    
    SELECT tLessonGUID AS GUID,
		tNumErrors AS NumErrors,
		tError AS `Error`;
    
END
//


/*

	aMuseumID CHAR(36),
    aLessonType VARCHAR(100),
    aName VARCHAR(200),
    aDescription TEXT,
    aCurriculumCode CHAR(20),
    aCurriculumTopic CHAR(100),
    aContent TEXT,
    aKeywords VARCHAR(1000),
    aInputFileID CHAR(36)
    
CALL UPLOAD_Lesson ('3F26C4F3-2C0F-493C-B235-40AED60D0F07', 'Lesson', 'test lesson', 
	'The essential guide to quadratic functions',
    'CAPS', 'Mathematics', 

    '# TEST LESSON

This is the end', null, null)

CALL UPLOAD_Lesson ('3F26C4F3-2C0F-493C-B235-40AED60D0F07', 'Lesson', 'test lesson', 
	'The essential guide to quadratic functions',
    'CAPS', 'Mathematics', 

    '# TEST LESSON

This is the end', null, null)


CALL UPLOAD_Categorization(565, 'C1BDE79A-5D1D-1D1E-1DF5-CF640589655D', 145, 'quadratic expressions');
CALL UPLOAD_Categorization(565, 'C1BDE79A-5D1D-1D1E-1DF5-CF640589655D', 145, 'algebra');
CALL UPLOAD_Categorization_CurriculumElement(565, 'C1BDE79A-5D1D-1D1E-1DF5-CF640589655D', '57B03B66-1A98-4331-B0D7-82F72C51975D');

*/
	
DELIMITER //
DROP PROCEDURE IF EXISTS UPLOAD_DigitalObject //
CREATE PROCEDURE UPLOAD_DigitalObject (
	aRefETID INT,
    aREfGUID CHAR(36),
    aFileName VARCHAR(255),
    aDescription VARCHAR(1000)
)
BEGIN

	DECLARE tDigitalObjectID BIGINT;
    DECLARE tDigitalObjectGUID CHAR(36);

	INSERT INTO DigitalObjects(RefETID, RefGUID, FileName, Description)
    VALUES(aRefETID, aREfGUID, aFileName, aDescription);
    
    SET tDigitalObjectID = LAST_INSERT_ID();
	SELECT GUID AS tDigitalObjectGUID FROM DigitalObjects WHERE ID = tDigitalObjectID;
    
    SELECT tDigitalObjectGUID AS GUID;    
    
END
//


DELIMITER //
DROP PROCEDURE IF EXISTS UPLOAD_Categorization //
CREATE PROCEDURE UPLOAD_Categorization (
	aRefETID INT,
    aREfGUID CHAR(36),
    aCategoryETID INT,
    aCategoryValueID CHAR(36),
    aCategoryValue VARCHAR(255)
)
BEGIN
-- used for the categorization for ALL content in One-Museum
-- insert only the CategoryValue, and a later process will link up to the vocabulary
-- this linkage may be automated or manual, and may use AI
-- RefETID
-- 565: Lessons
-- CategoryETID:
-- 125: PerOrgs
-- 145: Subjects
-- 155: CurriculumElements

	DECLARE tCategorizationID BIGINT;
    DECLARE tCategorizationGUID CHAR(36);
    
	INSERT INTO Categorizations (RefETID, RefGUID, CategoryETID, CategoryValueID, CategoryValue)
	VALUES (aREfETID, aRefGUID, aCategoryETID, aCategoryValueID, aCategoryValue);

    SET tCategorizationID = LAST_INSERT_ID();
	SELECT GUID AS tCategorizationGUID FROM Categorizations WHERE ID = tCategorizationID;
    
    SELECT tCategorizationGUID AS GUID;   

END
//

/*
CALL UPLOAD_Categorization (565, '5B4B42F6-FBB7-1114-323A-77E1B44783A7',
	155, '8CCDEFA9-F107-49EE-81E4-C1A15D948316', 'CAPS:VA491')
*/


DELIMITER //
DROP PROCEDURE IF EXISTS UPLOAD_Categorization_CurriculumElement //
CREATE PROCEDURE UPLOAD_Categorization_CurriculumElement (
	aRefETID INT,
    aREfGUID CHAR(36),
    aCategoryValueID CHAR(36)
)
BEGIN
-- used for the categorization for ALL content in One-Museum
-- insert only the CategoryValue, and a later process will link up to the vocabulary
-- this linkage may be automated or manual, and may use AI
-- RefETID
--	565: Lessons
-- CategoryETID:
--	125: PerOrgs
--  145: Subjects
--  155: CurriculumElements

	INSERT INTO Categorizations (RefETID, RefGUID, CategoryEtID, CategoryValueID)
	VALUES (aREfETID, aRefGUID, 155, aCategoryValueID);

END
//




/*


*/
