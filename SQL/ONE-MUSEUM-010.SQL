/*
** ONE-MUSEUM.COM
** SCRIPT: ONE-MUSEUM-004.SQL : TESTING THE DATABASE
**
** TABLE: _TEST_LOG: The log of all tests
*/



-- ================================================================================================
DELIMITER //
CREATE TABLE _TEST_LOG
(
    ID SERIAL,
    Code VARCHAR(4) NOT NULL,
    EntryType VARCHAR(20) NOT NULL,
    DateEntry DATETIME DEFAULT NOW(),
    Title VARCHAR(100) NULL,
    Details VARCHAR(1000) NULL
)
ENGINE=InnoDB COLLATE=utf8mb4_unicode_ci
COMMENT ''
//

-- ================================================================================================
DELIMITER //
CREATE PROCEDURE _TEST_LOGGER (
	IN aCode VARCHAR(4),
	IN aEntryType VARCHAR(20),
    IN aTitle VARCHAR(100),
    IN aDetails VARCHAR(1000)
)
BEGIN
	INSERT INTO _TEST_LOG (Code, EntryType, Title, Details)
    VALUES (aCode, aEntryType, aTitle, aDetails);
END
//

DELIMITER //
DROP PROCEDURE IF EXISTS _EXECI
//
CREATE PROCEDURE _EXECI(IN query MEDIUMTEXT)
	MODIFIES SQL DATA
	SQL SECURITY DEFINER
BEGIN
	SET @q = query;
	PREPARE stmt FROM @q;
	EXECUTE stmt;
	DEALLOCATE PREPARE stmt;
END
//

DELIMITER //
DROP PROCEDURE IF EXISTS _TABLE_CLEAR
//
CREATE PROCEDURE _TABLE_CLEAR (aCode VARCHAR(4), aTable VARCHAR(50))
BEGIN
	CALL _TEST_LOGGER ('0101', 'CLEAN', CONCAT('DELETING ',aTable), '');
	SET SQL_SAFE_UPDATES = 0;
	CALL _EXECI(CONCAT('DELETE FROM `', aTable, '`'));
END
//

DELIMITER //
DROP PROCEDURE IF EXISTS _DATA_CLEAN//
CREATE PROCEDURE _DATA_CLEAN ()
BEGIN
	CALL _TEST_LOGGER ('0100', 'CLEAN', 'Cleaning out all existing data', '');
	SET SQL_SAFE_UPDATES = 0;
    CALL _TABLE_CLEAR('0101', 'Notes');
    CALL _TABLE_CLEAR('0102', 'NoteTypes');
    CALL _TABLE_CLEAR('0103', 'Names');
    CALL _TABLE_CLEAR('0104', 'NameTypes');
    CALL _TABLE_CLEAR('0105', 'Identifiers');
    CALL _TABLE_CLEAR('0106', 'IdentifierTypes');
    CALL _TABLE_CLEAR('0110', 'Categorizations');
    CALL _TABLE_CLEAR('0111', 'CategoryValues');
    CALL _TABLE_CLEAR('0112', 'CategoryClasses');
    CALL _TABLE_CLEAR('0120', 'Exhibitions');
    CALL _TABLE_CLEAR('0121', 'ExhibitionTypes');
    CALL _TABLE_CLEAR('0123', 'Lessons');
    CALL _TABLE_CLEAR('0124', 'LessonTypes');
    CALL _TABLE_CLEAR('0125', 'Stories');
    CALL _TABLE_CLEAR('0126', 'StoryTypes');
    CALL _TABLE_CLEAR('0130', 'Items');
    CALL _TABLE_CLEAR('0131', 'ItemTypes');
    CALL _TABLE_CLEAR('0135', 'Collections');
    CALL _TABLE_CLEAR('0136', 'CollectionTypes');
    CALL _TABLE_CLEAR('0140', 'Museums');
    CALL _TABLE_CLEAR('0141', 'MuseumTypes');
    CALL _TABLE_CLEAR('0145', 'Custodians');
    CALL _TABLE_CLEAR('0146', 'CustodianForms');
    CALL _TABLE_CLEAR('0151', 'Curricula');
    CALL _TABLE_CLEAR('0152', 'CurriculumElements');
    CALL _TABLE_CLEAR('0153', 'CurriculumSubjects');
    CALL _TABLE_CLEAR('0154', 'CurriculumLevels');
    CALL _TABLE_CLEAR('0160', 'SessionData');
    CALL _TABLE_CLEAR('0161', 'Sessions');
    CALL _TABLE_CLEAR('0162', 'UserSecretQuestions');
    CALL _TABLE_CLEAR('0163', 'SecretQuestions');
    CALL _TABLE_CLEAR('0165', 'UserEntities');
    CALL _TABLE_CLEAR('0166', 'UserFolders');
    CALL _TABLE_CLEAR('0168', 'Users');
    CALL _TABLE_CLEAR('0199', '_TEST_LOG');
END
//


DELIMITER //
DROP PROCEDURE IF EXISTS _DATA_SETUP//
DELIMITER //
CREATE PROCEDURE _DATA_SETUP ()
BEGIN

	CALL _TEST_LOGGER ('0000', 'START', 'Start a new test', '');
       
END
//

DELIMITER //
CREATE PROCEDURE _TEST_RUN ()
BEGIN
	CALL _DATA_CLEAN();
    CALL _DATA_SETUP();
    
	CALL _TEST_001();
    
    CALL _TEST_LOGGER('9999', 'END', 'End of test', '');
    SELECT * FROM _TEST_LOG;
END
//



DELIMITER //
CREATE PROCEDURE _TEST_001 ()
BEGIN

	

END
//


CALL _TEST_RUN();



