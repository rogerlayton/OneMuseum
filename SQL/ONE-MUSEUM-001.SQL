/*
** ONE-MUSEUM.COM
** SCRIPT: ONE-MUSEUM-001.SQL : TABLE SETUP
**
== TABLE DESIGN STANDARDS:
==		PRIMARY KEY (PK): always named "GUID" and this is provided by the INSERT statement
==			or is created at insertion time through an INSERT TRIGGER
==
==
** ----------------------------------------------------------------------------------------------
** STANDARD TABLE STRUCTURE
** ----------------------------------------------------------------------------------------------
**
** Each table is based on the BOA standards, which requires the following core elements
**
** GUID: a globally unique identified, or UUID, this is either created by the museum (as for
**		ETHER Base, or is created at the time of the loading of the object.
** ID: (PK) a unique BIGINT used to sequence the records
** Name: the name of the object (for most tables)
** Description: a short description to be used as an abstract
** UpdatedBy: link to a user
** UpdatedOn: a datetime value
**
** ----------------------------------------------------------------------------------------------
** AMENDMENT HISTORY TABLE
** ----------------------------------------------------------------------------------------------
**
** This table is used to keep track of all changes to the database
** This is not applicable to the core content of OneMuseum, since this is read-only
** and is loaded from the museums.
** However, this is applicable to all user-created information, and to core administrative tables
**
** The AmendmentHistory table 
*/

/*
-- RUN THESE MANUALLY - COMMENTED OUT TO PREVENT ACCIDENTAL DELETION

-- DROP DATABASE IF EXISTS onemuseum;
CREATE DATABASE onemuseum
	COLLATE=utf8mb4_unicode_ci;

*/

SET sql_log_bin = OFF;

USE onemuseum;

-- --------------------------------------------------------------------------------------------------
-- UTILITY PROCEDURES
-- --------------------------------------------------------------------------------------------------

-- --------------------------------------------------------------------------------------------------
DELIMITER //
DROP FUNCTION `UTIL_NEWID`
//
CREATE FUNCTION `UTIL_NEWID`() RETURNS char(36) CHARSET utf8mb4 DETERMINISTIC
BEGIN
-- ADAPTED FROM NEWID : http://www.sugarcrm.com/forums/archive/index.php/t-2895.html
-- My Adaptation supports the correct SQL Server Approach
  DECLARE var_char CHAR(1);
  DECLARE var_time CHAR(4) DEFAULT '0000';
  DECLARE var_count INT DEFAULT 32;
  DECLARE var_guid CHAR(36) DEFAULT '';


  SET var_time = RIGHT(CONCAT("0000", HEX(UNIX_TIMESTAMP())), 4);
  SET var_guid = LOWER(var_time);

  WHILE var_count > 0 DO
    IF (var_count = 28 OR var_count = 23 OR var_count = 18 OR var_count = 13) THEN
      SET var_guid = CONCAT(var_guid, "-");
    ELSE
      SET var_char = HEX(FLOOR(RAND()*16));
      SET var_guid = CONCAT(var_guid, LOWER(var_char));
    END IF;
    SET var_count = var_count - 1;
  END WHILE;

  RETURN UPPER(var_guid);
END//

-- --------------------------------------------------------------------------------------------------
-- TABLES: CORE
-- --------------------------------------------------------------------------------------------------

DELIMITER //
CREATE TABLE EntityTypes
(
	GUID CHAR(36) NULL DEFAULT '#NONE#',
    ETID INT NOT NULL PRIMARY KEY,
    Code VARCHAR(5) NULL,
    EntityName VARCHAR(100) NOT NULL UNIQUE,
    TableName VARCHAR(100) NOT NULL UNIQUE,
    Description VARCHAR(2000) NULL,
    IsCommon BIT NOT NULL DEFAULT 0,
    IsEntity BIT NOT NULL DEFAULT 0,
    IsVocabulary BIT NOT NULL DEFAULT 0,
    IsCategory BIT NOT NULL DEFAULT 0,
    EmitSQLNum INT NOT NULL DEFAULT 1
)
ENGINE=InnoDB
//

DELIMITER //
CREATE TRIGGER EntityTypes_TR_GUID
BEFORE INSERT ON EntityTypes
FOR EACH ROW
BEGIN
-- if no GUID provided as the PK, then create one now
  IF new.GUID = '#NONE#' THEN
    SET new.GUID = UTIL_NEWID();
  END IF;
END
//


-- --------------------------------------------------------------------------------------------------
-- TABLES: USER MANAGEMENT
-- --------------------------------------------------------------------------------------------------

DELIMITER //
CREATE TABLE UserRoleTypes
(
	GUID CHAR(36) NOT NULL DEFAULT '#NONE#' PRIMARY KEY,
    ID SERIAL,
    Code VARCHAR(5) NULL,
    Name VARCHAR(100) NOT NULL UNIQUE,
    Description VARCHAR(2000) NULL
)
ENGINE=InnoDB COLLATE utf8_unicode_ci
//

DELIMITER //
CREATE TRIGGER UserRoleTypes_TR_GUID
BEFORE INSERT ON UserRoleTypes
FOR EACH ROW
BEGIN
-- if no GUID provided as the PK, then create one now
  IF new.GUID = '#NONE#' THEN
    SET new.GUID = UTIL_NEWID();
  END IF;
END
//


-- ----------------------------------------------------------------------------------------
DELIMITER //
CREATE TABLE Users
(
	GUID CHAR(36) NOT NULL DEFAULT '#NONE#' PRIMARY KEY,
    GUIDalt CHAR(36) NOT NULL DEFAULT '#NONE#'
		COMMENT 'This alternative GUID can be used to uniquely identify the user without having to use the PK',
    ID SERIAL,
    UserRoleTypeID CHAR(36) NOT NULL,
    UserName VARCHAR(20) NOT NULL UNIQUE,
    Email VARCHAR(120) NOT NULL,
    Image_File VARCHAR(20) NOT NULL DEFAULT 'default.jpg',
    Password VARCHAR(128) NOT NULL,
    DisplayName VARCHAR(200) NOT NULL,
    FullName VARCHAR(100) NULL,
    UserStatus TINYINT NOT NULL DEFAULT 0,
    DateBirth DATETIME NULL,
    NamedPlaceID CHAR(36) NULL,
    email_confirmed BOOLEAN,
    email_confirmed_on DATETIME,
    registered_on DATETIME,
    email_confirmation_sent_on DATETIME
)
ENGINE=InnoDB COLLATE utf8_unicode_ci
COMMENT ''
//

/*
ALTER TABLE Users
ADD email_confirmed BOOLEAN,
ADD email_confirmed_on DATETIME,
ADD registered_on DATETIME,
ADD email_confirmation_sent_on DATETIME;

*/


DELIMITER //
CREATE TRIGGER Users_TR_GUID
BEFORE INSERT ON Users
FOR EACH ROW
BEGIN
  IF new.GUID = '#NONE#' THEN
    SET new.GUID = UTIL_NEWID();
  END IF;
  -- always set this alternative GUID for usage in cookie management
  -- this should also be reset to a new UTIL_NEWID() when the user changes their password
  SET new.GUIDalt = UTIL_NEWID();
END
//



-- ----------------------------------------------------------------------------------------
DELIMITER //
CREATE TABLE SecretQuestions
(
	GUID CHAR(36) NOT NULL DEFAULT '#NONE#' PRIMARY KEY,
    ID SERIAL,
    Question VARCHAR(200) NOT NULL UNIQUE,
    Seq INT NULL NULL DEFAULT 0
)
ENGINE=InnoDB COLLATE utf8_unicode_ci
COMMENT ''
//

DELIMITER //
CREATE TRIGGER SecretQuestions_TR_GUID
BEFORE INSERT ON SecretQuestions
FOR EACH ROW
BEGIN
  IF new.GUID = '#NONE#' THEN
    SET new.GUID = UTIL_NEWID();
  END IF;
END
//


-- ----------------------------------------------------------------------------------------
DELIMITER //
CREATE TABLE UserSecretQuestions
(
	GUID CHAR(36) NOT NULL DEFAULT '#NONE#' PRIMARY KEY,
    ID SERIAL,
    UserID CHAR(36) NOT NULL,
    SecretQuestionID CHAR(36) NOT NULL,
    Answer VARCHAR(100) NOT NULL
)
ENGINE=InnoDB COLLATE utf8_unicode_ci
COMMENT ''
//

DELIMITER //
CREATE TRIGGER UserSecretQuestions_TR_GUID
BEFORE INSERT ON UserSecretQuestions
FOR EACH ROW
BEGIN
  IF new.GUID = '#NONE#' THEN
    SET new.GUID = UTIL_NEWID();
  END IF;
END
//


-- ----------------------------------------------------------------------------------------
DELIMITER //
CREATE TABLE UserFolders
(
	GUID CHAR(36) NOT NULL DEFAULT '#NONE#' PRIMARY KEY,
    ID SERIAL,
    ParentID CHAR(36) NULL,
    UserID CHAR(36) NOT NULL,
    Name CHAR(100) NOT NULL,
    Description VARCHAR(100) NULL
)
ENGINE=InnoDB COLLATE utf8_unicode_ci
COMMENT ''
//

DELIMITER //
CREATE TRIGGER UserFolders_TR_GUID
BEFORE INSERT ON UserFolders
FOR EACH ROW
BEGIN
  IF new.GUID = '#NONE#' THEN
    SET new.GUID = UTIL_NEWID();
  END IF;
END
//


-- ----------------------------------------------------------------------------------------
DELIMITER //
CREATE TABLE UserEntities
(
	GUID CHAR(36) NOT NULL DEFAULT '#NONE#' PRIMARY KEY,
    ID SERIAL,
    UserID CHAR(36) NOT NULL,
    UserFolderID CHAR(36) NULL,
    RefETID INT NOT NULL,
    ETName VARCHAR(100) NOT NULL,
    RefGUID CHAR(36) NOT NULL,
    EntityName CHAR(100) NOT NULL,
    Museum CHAR(100) NULL,
    Note VARCHAR(100) NULL,
    DateLinked DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
)
ENGINE=InnoDB COLLATE utf8_unicode_ci
COMMENT ''
//

DELIMITER //
CREATE TRIGGER UserEntities_TR_GUID
BEFORE INSERT ON UserEntities
FOR EACH ROW
BEGIN
  IF new.GUID = '#NONE#' THEN
    SET new.GUID = UTIL_NEWID();
  END IF;
END
//


-- ----------------------------------------------------------------------------------------
DELIMITER //
CREATE TABLE UserNoteTypes
(
	GUID CHAR(36) NOT NULL DEFAULT '#NONE#' PRIMARY KEY,
    ID SERIAL,
    Code VARCHAR(5) NULL,
    Name VARCHAR(100) NOT NULL UNIQUE,
    ScopingNote VARCHAR(2000) NULL
)
ENGINE=InnoDB COLLATE utf8_unicode_ci
//

DELIMITER //
CREATE TRIGGER UserNoteTypes_TR_GUID
BEFORE INSERT ON UserNoteTypes
FOR EACH ROW
BEGIN
-- if no GUID provided as the PK, then create one now
  IF new.GUID = '#NONE#' THEN
    SET new.GUID = UTIL_NEWID();
  END IF;
END
//


-- ----------------------------------------------------------------------------------------
DELIMITER //
CREATE TABLE UserNotes
(
	GUID CHAR(36) NOT NULL DEFAULT '#NONE#' PRIMARY KEY,
    ID SERIAL,
    UserID CHAR(36) NULL,
    RefETID INT NOT NULL,
    ETID CHAR(100) NOT NULL,
    RefGUID CHAR(36) NOT NULL,
    EntityName CHAR(200) NOT NULL,
    Museum VARCHAR(100) NULL,
    UserNoteTypeID CHAR(36) NOT NULL,
    UserNote TEXT NOT NULL
)
ENGINE=InnoDB COLLATE utf8_unicode_ci
COMMENT 'All entities can be categorized to provide contextual information as an aid to cataloguing and discovery.'
//

DELIMITER //
CREATE TRIGGER UserNotes_TR_GUID
BEFORE INSERT ON UserNotes
FOR EACH ROW
BEGIN
  IF new.GUID = '#NONE#' THEN
    SET new.GUID = UTIL_NEWID();
  END IF;
END
//


-- ----------------------------------------------------------------------------------------
DELIMITER //
CREATE TABLE UserFilters
(
	GUID CHAR(36) NOT NULL DEFAULT '#NONE#' PRIMARY KEY,
    ID SERIAL,
    UserID CHAR(36) NOT NULL,
    IsCurrent BIT NOT NULL DEFAULT 1
		COMMENT 'Each user has a single default User Filter which is what they work with. From here they are save into other filter or loaded from here into the current',
	Name CHAR(100) NOT NULL
		COMMENT 'The unique name for each user for the saved filters',
	Description TEXT NULL,
    Note TEXT NULL,
    DateCreated DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
)
ENGINE=InnoDB COLLATE utf8_unicode_ci
COMMENT ''
//

DELIMITER //
CREATE TRIGGER UserFilters_TR_GUID
BEFORE INSERT ON UserFilters
FOR EACH ROW
BEGIN
  IF new.GUID = '#NONE#' THEN
    SET new.GUID = UTIL_NEWID();
  END IF;
END
//


-- ----------------------------------------------------------------------------------------
DELIMITER //
CREATE TABLE UserFilterValues
(
	GUID CHAR(36) NOT NULL DEFAULT '#NONE#' PRIMARY KEY,
    ID SERIAL,
    UserFilterID CHAR(36) NOT NULL,
    CategoryETID CHAR(36) NOT NULL,
    CategoryValueID CHAR(36) NULL
		COMMENT 'The specific category value from the lists of Categories, from which the CategoryClass can also be determined.',
    CategoryValue VARCHAR(200) NULL
		COMMENT 'The category value from the category table from which this came, from CategoryETID',
    CategoryValueExt VARCHAR(200) NULL
		COMMENT 'Values not found in category table, ',
	CategoryClass CHAR(100) NULL,
	DateDescription VARCHAR(100) NULL,
	DateMin BIGINT NULL,
    DateMax BIGINT NULL,
    Location GEOMETRY NULL,
    Priority INT NOT NULL DEFAULT 1,
    DateCreated DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
)
ENGINE=InnoDB COLLATE utf8_unicode_ci
COMMENT ''
//

DELIMITER //
CREATE TRIGGER UserFilterValues_TR_GUID
BEFORE INSERT ON UserFilterValues
FOR EACH ROW
BEGIN
  IF new.GUID = '#NONE#' THEN
    SET new.GUID = UTIL_NEWID();
  END IF;
END
//


-- ----------------------------------------------------------------------------------------
DELIMITER //
CREATE TABLE Sessions
(
	GUID CHAR(36) NOT NULL DEFAULT '#NONE#' PRIMARY KEY,
    ID SERIAL,
    UserID CHAR(36) NOT NULL,
    DateStarted DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP(),
    DateEnded DATETIME NULL,
    IsTimedOut BIT NOT NULL DEFAULT 0
		COMMENT 'If the session timed out instead of the user logging out'
)
ENGINE=InnoDB COLLATE utf8_unicode_ci
COMMENT ''
//

DELIMITER //
CREATE TRIGGER Sessions_TR_GUID
BEFORE INSERT ON Sessions
FOR EACH ROW
BEGIN
  IF new.GUID = '#NONE#' THEN
    SET new.GUID = UTIL_NEWID();
  END IF;
END
//



-- ----------------------------------------------------------------------------------------
DELIMITER //
CREATE TABLE SessionData
(
	GUID CHAR(36) NOT NULL DEFAULT '#NONE#' PRIMARY KEY,
    ID SERIAL,
    SessionID CHAR(36) NOT NULL,
    DateStarted DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP(),
    Type VARCHAR(10) NULL
		COMMENT 'The type of data record here - not limited to URL activity. GET, POST, COMMENT, ERROR, ...',
    URL VARCHAR(1000) NULL
		COMMENT 'The full URL which the user is using for this new page',
	POSTData JSON NULL
		COMMENT 'The POST values if this was a POST request',
    SearchString VARCHAR(255) NULL
		COMMENT 'The seacrh string the user entered',
    RefETID INT NULL,
    RefGUID CHAR(36) NULL
		COMMENT 'Which entities did the user open',
    UserNote TEXT NULL
		COMMENT 'The user can enter notes during the session',
	ETName VARCHAR(100) NULL,
    EntityName VARCHAR(1000) NULL
)
ENGINE=InnoDB COLLATE utf8_unicode_ci
COMMENT ''
//

DELIMITER //
CREATE TRIGGER SessionData_TR_GUID
BEFORE INSERT ON SessionData
FOR EACH ROW
BEGIN
  IF new.GUID = '#NONE#' THEN
    SET new.GUID = UTIL_NEWID();
  END IF;
END
//

-- --------------------------------------------------------------------------------------------------
-- TABLES: COMMUNITY MANAGEMENT
-- --------------------------------------------------------------------------------------------------

DELIMITER //
CREATE TABLE Communities
(
	GUID CHAR(36) NOT NULL DEFAULT '#NONE#' PRIMARY KEY,
    ID SERIAL,
    Name VARCHAR(100) NULL,
    Description VARCHAR(200) NOT NULL,
    LongDescription VARCHAR(2000) NULL,
    Keywords VARCHAR(255) NOT NULL
)
ENGINE=InnoDB COLLATE utf8_unicode_ci
COMMENT 'A community is a group of users with a shared interest.'
//

DELIMITER //
CREATE TRIGGER Communities_TR_GUID
BEFORE INSERT ON Communities
FOR EACH ROW
BEGIN
  IF new.GUID = '#NONE#' THEN
    SET new.GUID = UTIL_NEWID();
  END IF;
END
//


-- ----------------------------------------------------------------------------------------
DELIMITER //
CREATE TABLE CommunityMembers
(
	GUID CHAR(36) NOT NULL DEFAULT '#NONE#' PRIMARY KEY,
    ID SERIAL,
    CommunityID CHAR(36) NOT NULL,
    UserID CHAR(36) NOT NULL,
    IsOwner BIT NOT NULL DEFAULT 0,
    Note VARCHAR(200) NULL
)
ENGINE=InnoDB COLLATE utf8_unicode_ci
COMMENT 'The users who are registered in a community.'
//

DELIMITER //
CREATE TRIGGER CommunityMembers_TR_GUID
BEFORE INSERT ON CommunityMembers
FOR EACH ROW
BEGIN
  IF new.GUID = '#NONE#' THEN
    SET new.GUID = UTIL_NEWID();
  END IF;
END
//


-- --------------------------------------------------------------------------------------------------
-- TABLES: POSTS
-- --------------------------------------------------------------------------------------------------

DELIMITER //
CREATE TABLE Posts
(
  GUID CHAR(36) NOT NULL DEFAULT '#NONE#' PRIMARY KEY,
  ID SERIAL,
  UserID CHAR(36) NOT NULL,
  Title VARCHAR(100) NULL,
  Date_Posted DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  Content TEXT NOT NULL
)
ENGINE=InnoDB COLLATE utf8_unicode_ci
COMMENT 'Posts submitted by users.'
//

DELIMITER //
CREATE TRIGGER Posts_TR_GUID
BEFORE INSERT ON Posts
FOR EACH ROW
BEGIN
  IF new.GUID = '#NONE#' THEN
    SET new.GUID = UTIL_NEWID();
  END IF;
END
//


-- --------------------------------------------------------------------------------------------------
-- TABLES: VOCABULARIES and CATEGORISATIONS
-- --------------------------------------------------------------------------------------------------

DELIMITER //
CREATE TABLE NamedPlaceTypes
(
	GUID CHAR(36) NOT NULL DEFAULT '#NONE#' PRIMARY KEY,
    ID SERIAL,
    ParentID CHAR(36) NULL,
    Code VARCHAR(5) NULL,
    Name VARCHAR(100) NOT NULL UNIQUE,
    ScopingNote VARCHAR(2000) NULL
)
ENGINE=InnoDB COLLATE utf8_unicode_ci
//

DELIMITER //
CREATE TRIGGER NamedPlaceTypes_TR_GUID
BEFORE INSERT ON NamedPlaceTypes
FOR EACH ROW
BEGIN
-- if no GUID provided as the PK, then create one now
  IF new.GUID = '#NONE#' THEN
    SET new.GUID = UTIL_NEWID();
  END IF;
END
//


-- ----------------------------------------------------------------------------------------
DELIMITER //
CREATE TABLE Countries
(
	GUID CHAR(36) NOT NULL DEFAULT '#NONE#' PRIMARY KEY,
    ID SERIAL,
    Num INT NOT NULL,
    Code2 CHAR(2) NOT NULL,
    Code3 CHAR(3) NOT NULL,
    Abbreviation VARCHAR(10) NULL,
    Name VARCHAR(100) NOT NULL,
    FormalName VARCHAR(100) NOT NULL,
    Continent VARCHAR(20) NULL,
	Note TEXT NULL,
    TopLevelDomain VARCHAR(10) NULL
)
ENGINE=InnoDB COLLATE utf8_unicode_ci
COMMENT 'The official ISO list of countries of the world, with associated codes and numbers and TLDs'
//

DELIMITER //
CREATE TRIGGER Countries_TR_GUID
BEFORE INSERT ON Countries
FOR EACH ROW
BEGIN
  IF new.GUID = '#NONE#' THEN
    SET new.GUID = UTIL_NEWID();
  END IF;
END
//


-- ----------------------------------------------------------------------------------------
DELIMITER //
DROP TABLE IF EXISTS NamedPlaces
//
CREATE TABLE NamedPlaces
(
	GUID CHAR(36) NOT NULL DEFAULT '#NONE#' PRIMARY KEY,
    ID SERIAL,
    ParentID CHAR(36) NULL,
    NamedPlaceTypeID CHAR(36) NULL,
    NamedPlaceType CHAR(255) NULL,
    Code VARCHAR(20) NULL,
    Name VARCHAR(100) NOT NULL,
	Description VARCHAR(2000) NULL,
    LocationDescription GEOMETRY NULL
		COMMENT 'GPS coordinates etc of the place',
	GPSLat DOUBLE NULL,
    GPSLong DOUBLE NULL,
    Notes TEXT NULL,
    MunicipalityID CHAR(36) NULL,
    ProvinceID CHAR(36) NULL,
    CountryID CHAR(36) NULL
)
ENGINE=InnoDB COLLATE utf8_unicode_ci
COMMENT 'All entities can be categorized to provide contextual information as an aid to cataloguing and discovery.'
//

DELIMITER //
CREATE TRIGGER NamedPlaces_TR_GUID
BEFORE INSERT ON NamedPlaces
FOR EACH ROW
BEGIN
  IF new.GUID = '#NONE#' THEN
    SET new.GUID = UTIL_NEWID();
  END IF;
END
//


-- ----------------------------------------------------------------------------------------
DELIMITER //
CREATE TABLE NamedEventTypes
(
	GUID CHAR(36) NOT NULL DEFAULT '#NONE#' PRIMARY KEY,
    ID SERIAL,
    ParentID CHAR(36) NULL,
    Code VARCHAR(5) NULL,
    Name VARCHAR(100) NOT NULL UNIQUE,
    ScopingNote VARCHAR(2000) NULL
)
ENGINE=InnoDB COLLATE utf8_unicode_ci
//

DELIMITER //
CREATE TRIGGER NamedEventTypes_TR_GUID
BEFORE INSERT ON NamedEventTypes
FOR EACH ROW
BEGIN
-- if no GUID provided as the PK, then create one now
  IF new.GUID = '#NONE#' THEN
    SET new.GUID = UTIL_NEWID();
  END IF;
END
//


-- ----------------------------------------------------------------------------------------
DELIMITER //
CREATE TABLE NamedEvents
(
	GUID CHAR(36) NOT NULL DEFAULT '#NONE#' PRIMARY KEY,
    ID SERIAL,
    NamedEventTypeID CHAR(36) NULL,
    NamedEventType CHAR(255) NULL,
    ParentID CHAR(36) NULL,
    Code VARCHAR(5) NULL,
    Name VARCHAR(100) NOT NULL UNIQUE,
	Description VARCHAR(2000) NULL,
    DateDescription CHAR(50) NULL,
    DateMin INT NULL,
    DateMax INT NULL,
    CountryID CHAR(36) NULL
)
ENGINE=InnoDB COLLATE utf8_unicode_ci
COMMENT 'A list of named events which can be used to associated any entity, each is linked to a time period.'
//

/*
ALTER TABLE NamedEvents
ADD CountryID CHAR(36) NULL;

*/

DELIMITER //
CREATE TRIGGER NamedEvents_TR_GUID
BEFORE INSERT ON NamedEvents
FOR EACH ROW
BEGIN
  IF new.GUID = '#NONE#' THEN
    SET new.GUID = UTIL_NEWID();
  END IF;
END
//


-- ----------------------------------------------------------------------------------------
DELIMITER //
CREATE TABLE PerOrgTypes
(
	GUID CHAR(36) NOT NULL DEFAULT '#NONE#' PRIMARY KEY,
    ID SERIAL,
    ParentID CHAR(36) NULL,
    Code VARCHAR(5) NULL,
    Name VARCHAR(100) NOT NULL UNIQUE,
    ScopingNote VARCHAR(2000) NULL
)
ENGINE=InnoDB COLLATE utf8_unicode_ci
//

DELIMITER //
CREATE TRIGGER PerOrgTypes_TR_GUID
BEFORE INSERT ON PerOrgTypes
FOR EACH ROW
BEGIN
-- if no GUID provided as the PK, then create one now
  IF new.GUID = '#NONE#' THEN
    SET new.GUID = UTIL_NEWID();
  END IF;
END
//

-- ----------------------------------------------------------------------------------------
DELIMITER //
CREATE TABLE PerOrgs
(
	GUID CHAR(36) NOT NULL DEFAULT '#NONE#' PRIMARY KEY,
    ID SERIAL,
    PerOrgTypeID CHAR(36) NOT NULL,
    IsPerson BIT DEFAULT 0,
    IsPeople BIT DEFAULT 0,
    IsOrganisation BIT DEFAULT 0,
    Name VARCHAR(200) NOT NULL,
    FullName VARCHAR(200) NULL,
    KnownAs VARCHAR(100) NULL,
    KnownFor VARCHAR(2000) NULL,
    Title VARCHAR(20) NULL,
    FirstName VARCHAR(50) NULL,
    LastName VARCHAR(50) NULL,
    MiddleNames VARCHAR(50) NULL,
    Suffix VARCHAR(20) NULL,
    Gender CHAR(1) NULL,
    DateOfBirth CHAR(20) NULL
		COMMENT 'Use DateDescription standard',
	DateOfBirthMin INT NULL,
    DateOfBirthMax INT NULL,
	DateOfDeath CHAR(20) NULL
		COMMENT 'Use DateDescription standard',
	DateOfDeathMin INT NULL,
    DateOfDeathMAx INT NULL,
    Note TEXT NULL
)
ENGINE=InnoDB COLLATE utf8_unicode_ci
COMMENT ''
//

DELIMITER //
CREATE TRIGGER PerOrgs_TR_GUID
BEFORE INSERT ON PerOrgs
FOR EACH ROW
BEGIN
  IF new.GUID = '#NONE#' THEN
    SET new.GUID = UTIL_NEWID();
  END IF;
END
//

/*
USE OneMuseum;
ALTER TABLE PerOrgs
ADD FullName VARCHAR(200) NULL AFTER Name;
*/

/*
USE OneMuseum;
ALTER TABLE PerOrgs
ADD KnownFor VARCHAR(2000) NULL AFTER FullName;
*/

/*
USE OneMuseum;
ALTER TABLE PerOrgs
ADD KnownAs VARCHAR(2000) NULL AFTER FullName;
*/

-- ----------------------------------------------------------------------------------------
DELIMITER //
CREATE TABLE PerOrgLinkTypes
(
	GUID CHAR(36) NOT NULL DEFAULT '#NONE#' PRIMARY KEY,
    ID SERIAL,
    ParentID CHAR(36) NULL,
    Code VARCHAR(5) NULL,
    Name VARCHAR(100) NOT NULL UNIQUE,
    IsReversible BIT NOT NULL DEFAULT 0,
    ReverseName VARCHAR(100) NULL
		COMMENT 'If this can be reversed: is-parent-of and is-child-of',
    ScopingNote VARCHAR(2000) NULL
)
ENGINE=InnoDB COLLATE utf8_unicode_ci
//

DELIMITER //
CREATE TRIGGER PerOrgLinkTypes_TR_GUID
BEFORE INSERT ON PerOrgLinkTypes
FOR EACH ROW
BEGIN
-- if no GUID provided as the PK, then create one now
  IF new.GUID = '#NONE#' THEN
    SET new.GUID = UTIL_NEWID();
  END IF;
END
//


-- ----------------------------------------------------------------------------------------
DELIMITER //
CREATE TABLE PerOrgLinks
(
	GUID CHAR(36) NOT NULL DEFAULT '#NONE#' PRIMARY KEY,
    ID SERIAL,
    PerOrgFromID CHAR(36) NOT NULL,
    PerOrgToID CHAR(36) NOT NULL,
    PerOrgLinkTypeID CHAR(36) NOT NULL
		COMMENT 'The link expressed in terms of FROM-LINK-TO such as A is-parent-of B or C worked-for D',
    PerOrgLinkType CHAR (50) NULL,
    DateDescription CHAR(100) NULL
		COMMENT 'From when to when was this link in place',
    DateMin INT NULL,
    DateMax INT NULL,
    Note TEXT NULL
)
ENGINE=InnoDB COLLATE utf8_unicode_ci
//

DELIMITER //
CREATE TRIGGER PerOrgLinks_TR_GUID
BEFORE INSERT ON PerOrgLinks
FOR EACH ROW
BEGIN
-- if no GUID provided as the PK, then create one now
  IF new.GUID = '#NONE#' THEN
    SET new.GUID = UTIL_NEWID();
  END IF;
END
//


-- ----------------------------------------------------------------------------------------
DELIMITER //
CREATE TABLE ChenhallNomenclature
(
	ID INT NOT NULL PRIMARY KEY,
    ParentID INT NULL
		COMMENT 'The link to the parent to establish the hierarchical structure. NULL for top-level categories',
    RecordType VARCHAR(50) NOT NULL
		COMMENT 'Category, Class, SubClass, Primary, Secondar, Tertiary',
	Level INT NOT NULL,
    Name VARCHAR(100) NOT NULL UNIQUE
		COMMENT 'The standard form of this name. Other names and translations are stored in the Names table',
    NameUK VARCHAR(100) NULL UNIQUE
		COMMENT 'The standard form of this name. Other names and translations are stored in the Names table',
    ScopingNote VARCHAR(2000) NULL
		COMMENT 'Scoping note to distinguish categories and terms under a parent',
    Category VARCHAR (255) NULL,
    Class VARCHAR (255) NULL,
    SubClass VARCHAR (255) NULL,
    PrimaryTerm VARCHAR(255) NULL,
    SecondaryTerm VARCHAR(255) NULL,
    TertiaryTerm VARCHAR(255) NULL,
    NonPreferredTerm VARCHAR(255) NULL,
    Definition TEXT NULL,
    DefinitionSource TEXT NULL,
    Notes TEXT NULL,
    Image_URL VARCHAR(255) NULL,
    Image_Source VARCHAR(255) NULL,
    OtherDesigParks VARCHAR(255) NULL,
    DoNotConfuseWith VARCHAR(255) Null
)
ENGINE=InnoDB COLLATE utf8_unicode_ci
//


-- ----------------------------------------------------------------------------------------
DELIMITER //
CREATE TABLE Subjects
(
	GUID CHAR(36) NOT NULL DEFAULT '#NONE#' PRIMARY KEY,
    ID SERIAL,
    ParentID CHAR(36) NULL,
    Abbreviation VARCHAR(10) NULL,
    Name VARCHAR(100) NOT NULL UNIQUE,
    Description VARCHAR(2000) NULL
)
ENGINE=InnoDB COLLATE utf8_unicode_ci
//

DELIMITER //
CREATE TRIGGER Subjects_TR_GUID
BEFORE INSERT ON Subjects
FOR EACH ROW
BEGIN
-- if no GUID provided as the PK, then create one now
  IF new.GUID = '#NONE#' THEN
    SET new.GUID = UTIL_NEWID();
  END IF;
END
//


-- ----------------------------------------------------------------------------------------
DELIMITER //
CREATE TABLE Curricula
(
	GUID CHAR(36) NOT NULL DEFAULT '#NONE#' PRIMARY KEY,
    ID SERIAL,
    Code VARCHAR(10) NULL,
    Name VARCHAR(100) NOT NULL UNIQUE,
    Description VARCHAR(2000) NULL,
    NamedPlaceID CHAR(36) NULL
		COMMENT 'In what country, province, etc. is this used',
    NamedPlace VARCHAR(100) NULL,
    Note TEXT NULL
)
ENGINE=InnoDB COLLATE utf8_unicode_ci
//

DELIMITER //
CREATE TRIGGER Curricula_TR_GUID
BEFORE INSERT ON Curricula
FOR EACH ROW
BEGIN
-- if no GUID provided as the PK, then create one now
  IF new.GUID = '#NONE#' THEN
    SET new.GUID = UTIL_NEWID();
  END IF;
END
//


-- ----------------------------------------------------------------------------------------
DELIMITER //
CREATE TABLE CurriculumSubjects
(
	GUID CHAR(36) NOT NULL DEFAULT '#NONE#' PRIMARY KEY,
    ID SERIAL,
    ParentID CHAR(36) NULL,
    CurriculumID CHAR(36) NULL,
    Curriculum CHAR(100) NULL,
    Code CHAR(20) NULL,
    Name VARCHAR(100) NOT NULL,
    Description VARCHAR(2000) NULL,
    IsHeader BIT DEFAULT 0,
    IsSubject BIT DEFAULT 1
)
ENGINE=InnoDB COLLATE utf8_unicode_ci
//

/*
USE OneMuseum;
ALTER TABLE CurriculumSubjects
ADD IsHeader BIT DEFAULT 0;

ALTER TABLE CurriculumSubjects
ADD IsSubject BIT DEFAULT 1

*/

DELIMITER //
CREATE TRIGGER CurriculumSubjects_TR_GUID
BEFORE INSERT ON CurriculumSubjects
FOR EACH ROW
BEGIN
-- if no GUID provided as the PK, then create one now
  IF new.GUID = '#NONE#' THEN
    SET new.GUID = UTIL_NEWID();
  END IF;
END
//


-- ----------------------------------------------------------------------------------------
DELIMITER //
CREATE TABLE CurriculumLevels
(
	GUID CHAR(36) NOT NULL DEFAULT '#NONE#' PRIMARY KEY,
    ID SERIAL,
    CurriculumID CHAR(36) NULL,
    Curriculum CHAR(100) NULL,
    ParentID CHAR(36) NULL,
    Code VARCHAR(20) NOT NULL,
    Name VARCHAR(100) NOT NULL,
    Description VARCHAR(2000) NULL,
    Seq INT DEFAULT 0
)
ENGINE=InnoDB COLLATE utf8_unicode_ci
//

DELIMITER //
CREATE TRIGGER CurriculumLevels_TR_GUID
BEFORE INSERT ON CurriculumLevels
FOR EACH ROW
BEGIN
-- if no GUID provided as the PK, then create one now
  IF new.GUID = '#NONE#' THEN
    SET new.GUID = UTIL_NEWID();
  END IF;
END
//


-- ----------------------------------------------------------------------------------------
DELIMITER //
CREATE TABLE CurriculumElementTypes
(
	GUID CHAR(36) NOT NULL DEFAULT '#NONE#' PRIMARY KEY,
    ID SERIAL,
    ParentID CHAR(36) NULL,
    Code VARCHAR(5) NULL,
    Name VARCHAR(100) NOT NULL UNIQUE,
    ScopingNote VARCHAR(2000) NULL,
    AppliesTo INT NULL,
    Seq INT NULL DEFAULT 0
)
ENGINE=InnoDB COLLATE utf8_unicode_ci
//

DELIMITER //
CREATE TRIGGER CurriculumElementTypes_TR_GUID
BEFORE INSERT ON CurriculumElementTypes
FOR EACH ROW
BEGIN
-- if no GUID provided as the PK, then create one now
  IF new.GUID = '#NONE#' THEN
    SET new.GUID = UTIL_NEWID();
  END IF;
END
//
     

-- ----------------------------------------------------------------------------------------
DELIMITER //
CREATE TABLE CurriculumElements
(
	GUID CHAR(36) NOT NULL DEFAULT '#NONE#' PRIMARY KEY,
    ID SERIAL,
    ParentID CHAR(36) NULL,
    CurriculumElementTypeID CHAR(36) NULL,
    CurriculumElementType VARCHAR(100) NULL,
    CurriculumID CHAR(36) NULL,
    Curriculum VARCHAR(100) NULL,
    CurriculumSubjectID CHAR(36) NULL,
    CurriculumSubject VARCHAR(100) NULL,
    CurriculumLevelID CHAR(36) NULL,
	CurriculumLevel VARCHAR(50) NULL,
    Code CHAR(20) NULL,
    Name VARCHAR(255) NOT NULL,
    Content TEXT NULL,
    Seq VARCHAR(10) NOT NULL DEFAULT 0
		COMMENT 'The sequence of the elements within the level in this curriculum'
)
ENGINE=InnoDB COLLATE utf8_unicode_ci
//

-- ALTER TABLE CurriculumElements
-- MODIFY `Name` VARCHAR(255) NOT NULL

-- ALTER TABLE CurriculumElements
-- MODIFY `Seq` VARCHAR(10)

-- ALTER TABLE CurriculumElements
-- CHANGE Description Content TEXT NULL

/*
USE OneMuseum;
ALTER TABLE CurriculumElements
ADD Hours FLOAT NULL AFTER Seq;
*/

DELIMITER //
ALTER TABLE CurriculumElements
ADD Term1 BIT NULL DEFAULT 0,
ADD Term2 BIT NULL DEFAULT 0, 
ADD Term3 BIT NULL DEFAULT 0, 
ADD Term4 BIT NULL DEFAULT 0
//


DELIMITER //
CREATE TRIGGER CurriculumElements_TR_GUID
BEFORE INSERT ON CurriculumElements
FOR EACH ROW
BEGIN
-- if no GUID provided as the PK, then create one now
  IF new.GUID = '#NONE#' THEN
    SET new.GUID = UTIL_NEWID();
  END IF;
END
//

-- --------------------------------------------------------------------------------------------------
-- TABLES - BOA COMMON
-- --------------------------------------------------------------------------------------------------

DELIMITER //
CREATE TABLE NameTypes
(
	GUID CHAR(36) NOT NULL DEFAULT '#NONE#' PRIMARY KEY,
    ID SERIAL,
    ParentID CHAR(36) NULL,
    Code VARCHAR(5) NULL,
    Name VARCHAR(100) NOT NULL UNIQUE,
    ScopingNote VARCHAR(2000) NULL,
    AppliesTo INT NULL,
    Seq INT NULL DEFAULT 0
)
ENGINE=InnoDB COLLATE utf8_unicode_ci
//

DELIMITER //
CREATE TRIGGER NameTypes_TR_GUID
BEFORE INSERT ON NameTypes
FOR EACH ROW
BEGIN
-- if no GUID provided as the PK, then create one now
  IF new.GUID = '#NONE#' THEN
    SET new.GUID = UTIL_NEWID();
  END IF;
END
//
        

-- ----------------------------------------------------------------------------------------
DELIMITER //
CREATE TABLE Names
(
	GUID CHAR(36) NOT NULL DEFAULT '#NONE#' PRIMARY KEY,
    ID SERIAL,
    RefETID INT NULL,
    RefGUID CHAR(36) NOT NULL,
    NameTypeID CHAR(36) NULL,
    NameType CHAR (50) NULL,
    Name VARCHAR(255) NOT NULL, 
    Note TEXT NULL
)
ENGINE=InnoDB COLLATE utf8_unicode_ci
//

DELIMITER //
CREATE TRIGGER Names_TR_GUID
BEFORE INSERT ON Names
FOR EACH ROW
BEGIN
  IF new.GUID = '#NONE#' THEN
    SET new.GUID = UTIL_NEWID();
  END IF;
END
//


-- ----------------------------------------------------------------------------------------
DELIMITER //
CREATE TABLE NoteTypes
(
	GUID CHAR(36) NOT NULL DEFAULT '#NONE#' PRIMARY KEY,
    ID SERIAL,
    ParentID CHAR(36) NULL,
    Code VARCHAR(5) NULL,
    Name VARCHAR(100) NOT NULL UNIQUE,
    ScopingNote VARCHAR(2000) NULL,
    AppliesTo INT NULL,
    Seq INT NULL DEFAULT 0
)
ENGINE=InnoDB COLLATE utf8_unicode_ci
//

DELIMITER //
CREATE TRIGGER NoteTypes_TR_GUID
BEFORE INSERT ON NoteTypes
FOR EACH ROW
BEGIN
-- if no GUID provided as the PK, then create one now
  IF new.GUID = '#NONE#' THEN
    SET new.GUID = UTIL_NEWID();
  END IF;
END
//
    

-- ----------------------------------------------------------------------------------------
DELIMITER //
CREATE TABLE Notes
(
	GUID CHAR(36) NOT NULL DEFAULT '#NONE#' PRIMARY KEY,
    ID SERIAL,
    RefETID INT NULL,
    RefGUID CHAR(36) NOT NULL,
    Note TEXT NOT NULL,
    NoteTypeID CHAR(36) NULL,
    NoteType CHAR (50) NULL
)
ENGINE=InnoDB COLLATE utf8_unicode_ci
COMMENT 'Note are used to provide a range of types of notes and descriptions about all types of entities'
//

DELIMITER //
CREATE TRIGGER Notes_TR_GUID
BEFORE INSERT ON Notes
FOR EACH ROW
BEGIN
  IF new.GUID = '#NONE#' THEN
    SET new.GUID = UTIL_NEWID();
  END IF;
END
//


-- ----------------------------------------------------------------------------------------
DELIMITER //
CREATE TABLE IdentifierTypes
(
	GUID CHAR(36) NOT NULL DEFAULT '#NONE#' PRIMARY KEY,
    ID SERIAL,
    ParentID CHAR(36) NULL,
    Code VARCHAR(5) NULL,
    Name VARCHAR(100) NOT NULL UNIQUE,
    ScopingNote VARCHAR(2000) NULL,
    AppliesTo INT NULL,
    Seq INT NULL DEFAULT 0
)
ENGINE=InnoDB COLLATE utf8_unicode_ci
//

DELIMITER //
CREATE TRIGGER IdentifierTypes_TR_GUID
BEFORE INSERT ON IdentifierTypes
FOR EACH ROW
BEGIN
-- if no GUID provided as the PK, then create one now
  IF new.GUID = '#NONE#' THEN
    SET new.GUID = UTIL_NEWID();
  END IF;
END
//
    

-- ----------------------------------------------------------------------------------------
DELIMITER //
CREATE TABLE Identifiers
(
	GUID CHAR(36) NOT NULL DEFAULT '#NONE#' PRIMARY KEY,
    ID SERIAL,
    RefETID INT NULL,
    RefGUID CHAR(36) NOT NULL,
	IdentifierTypeID CHAR(36) NULL,
    IdentifierType CHAR (50) NULL,
    Identifier VARCHAR(255) NOT NULL
)
ENGINE=InnoDB COLLATE utf8_unicode_ci
//

DELIMITER //
CREATE TRIGGER Identifiers_TR_GUID
BEFORE INSERT ON Identifiers
FOR EACH ROW
BEGIN
  IF new.GUID = '#NONE#' THEN
    SET new.GUID = UTIL_NEWID();
  END IF;
END
//


-- ----------------------------------------------------------------------------------------
DELIMITER //
CREATE TABLE RoleTypes
(
	GUID CHAR(36) NOT NULL DEFAULT '#NONE#' PRIMARY KEY,
    ID SERIAL,
    ParentID CHAR(36) NULL,
    Code VARCHAR(5) NULL,
    Name VARCHAR(100) NOT NULL UNIQUE,
    ReverseName VARCHAR(100) NULL,
    ScopingNote VARCHAR(2000) NULL,
    AppliesTo INT NULL,
    Seq INT NULL DEFAULT 0
)
ENGINE=InnoDB COLLATE utf8_unicode_ci
//

DELIMITER //
CREATE TRIGGER RoleTypes_TR_GUID
BEFORE INSERT ON RoleTypes
FOR EACH ROW
BEGIN
-- if no GUID provided as the PK, then create one now
  IF new.GUID = '#NONE#' THEN
    SET new.GUID = UTIL_NEWID();
  END IF;
END
//
    

-- ----------------------------------------------------------------------------------------
DELIMITER //
CREATE TABLE Roles
(
	GUID CHAR(36) NOT NULL DEFAULT '#NONE#' PRIMARY KEY,
    ID SERIAL,
    RefETID INT NULL,
    RefGUID CHAR(36) NOT NULL,
    PerOrgID CHAR(36) NOT NULL,
	RoleTypeID CHAR(36) NULL,
    RoleType CHAR (50) NULL,
    DateDescription VARCHAR(100) NULL,
    DateMin BIGINT NULL,
    DateMax BIGINT NULL,
    Note TEXT NULL
)
ENGINE=InnoDB COLLATE utf8_unicode_ci
//

DELIMITER //
CREATE TRIGGER Roles_TR_GUID
BEFORE INSERT ON Roles
FOR EACH ROW
BEGIN
  IF new.GUID = '#NONE#' THEN
    SET new.GUID = UTIL_NEWID();
  END IF;
END
//


-- ----------------------------------------------------------------------------------------
DELIMITER //
CREATE TABLE EventTypes
(
	GUID CHAR(36) NOT NULL DEFAULT '#NONE#' PRIMARY KEY,
    ID SERIAL,
    ParentID CHAR(36) NULL,
    Code VARCHAR(5) NULL,
    Name VARCHAR(100) NOT NULL UNIQUE,
    AppliesTo INT NULL,
    ScopingNote VARCHAR(2000) NULL,
    Seq INT NOT NULL DEFAULT 0
)
ENGINE=InnoDB COLLATE utf8_unicode_ci
COMMENT ''
//

DELIMITER //
CREATE TRIGGER EventTypes_TR_GUID
BEFORE INSERT ON EventTypes
FOR EACH ROW
BEGIN
  IF new.GUID = '#NONE#' THEN
    SET new.GUID = UTIL_NEWID();
  END IF;
END
//


-- ----------------------------------------------------------------------------------------
DELIMITER //
CREATE TABLE Events
(
	GUID CHAR(36) NOT NULL DEFAULT '#NONE#' PRIMARY KEY,
    ID SERIAL,
    RefETID INT NULL,
    RefGUID CHAR(36) NOT NULL,
    Event VARCHAR(255) NOT NULL,
    EventTypeID CHAR(36) NULL,
    EventType VARCHAR(100) NULL,
    NamedPlaceID CHAR(36) NULL,
    NamedPlace VARCHAR(255) NULL,
    DateDescription VARCHAR(100) NOT NULL,
    DateMin BIGINT NULL,
    DateMax BIGINT NULL,
    Note TEXT NULL
)
ENGINE=InnoDB COLLATE utf8_unicode_ci
COMMENT 'Events held at the museum to be placed onto the calendar'
//

DELIMITER //
CREATE TRIGGER Events_TR_GUID
BEFORE INSERT ON Events
FOR EACH ROW
BEGIN
  IF new.GUID = '#NONE#' THEN
    SET new.GUID = UTIL_NEWID();
  END IF;
END
//


-- ----------------------------------------------------------------------------------------
DELIMITER //
CREATE TABLE Categorizations
(
	GUID CHAR(36) NOT NULL DEFAULT '#NONE#' PRIMARY KEY,
    ID SERIAL,
    RefETID INT NOT NULL 
		COMMENT 'The type of entity being categorized: Museums, Collections, Items, Exhibitions, Stories',
    RefGUID CHAR(36) NOT NULL
		COMMENT 'The GUID of the entity to which this categorization applies',
    CategorizationNum INT NOT NULL DEFAULT 1
		COMMENT 'There can be many categorizations for an individual Entity=RefGUID.
        If they have different CategorizationNums then they are ORs, and those that have the same are AND relationships',
	CategoryETID INT NOT NULL,
    CategoryValueID CHAR(36) NULL
		COMMENT 'The specific category value from the lists of Categories, from which the CategoryClass can also be determined.',
	CategoryValue VARCHAR(200) NULL
		COMMENT 'The values as extracted from the category tables (NamedEvents, NamedPlaces, Subject, PerOrgs, CurriculumElements, ItemTypes
		at time of this record being created. This is done with the insert trigger',
	CategoryClass CHAR(100) NULL
		COMMENT 'The class of the category, in the case that none of the existing classes are sufficient for categorization',
    CategoryValueExt VARCHAR(200) NULL
		COMMENT 'The category when this is not included into the lists of categories or is not from a list, such as a specific date.
        This is where all original values are stored before they are selected into the categoryvalueID etc.',
	DateDescription VARCHAR(100) NULL
		COMMENT 'The date in the ETHER Date Format',
	DateMin BIGINT NULL
		COMMENT 'Minimum date extracted from DateDescription',
    DateMax BIGINT NULL
		COMMENT 'Maximum date extracted from DateDescription',
    Location GEOMETRY NULL
		COMMENT 'Location expressed as a GEOMETRY variable - for use in spatial queries',
    Priority INT NOT NULL DEFAULT 1
		COMMENT 'How important is this category for this entity - no scale determined as yet',
    Note VARCHAR(1000) NULL
)
ENGINE=InnoDB COLLATE utf8_unicode_ci
COMMENT 'All entities can be categorized to provide contextual information as an aid to cataloguing and discovery.'
//

DELIMITER //
CREATE TRIGGER Categorizations_TR_GUID
BEFORE INSERT ON Categorizations
FOR EACH ROW
BEGIN
  IF new.GUID = '#NONE#' THEN
    SET new.GUID = UTIL_NEWID();
  END IF;
  -- TODO set the category value here redundantly to avoid much computation to find this when needed
  -- possibly to be included later, for now handle this in the OneMuseumIngestor
  -- SET CategoryValue = GetCategory(CategoryETID, CategoryValueID);
END
//



-- --------------------------------------------------------------------------------------------------
-- TABLES: APPLICATION-SPECIFIC
-- --------------------------------------------------------------------------------------------------


DELIMITER //
CREATE TABLE MuseumForms
(
	GUID CHAR(36) NOT NULL DEFAULT '#NONE#' PRIMARY KEY,
    ID SERIAL,
    Code VARCHAR(5) NULL,
    Name VARCHAR(100) NOT NULL UNIQUE,
    Description VARCHAR(2000) NULL,
    ScopingNote TEXT NULL
)
ENGINE=InnoDB COLLATE utf8_unicode_ci
//

DELIMITER //
CREATE TRIGGER MuseumForms_TR_GUID
BEFORE INSERT ON MuseumForms
FOR EACH ROW
BEGIN
-- if no GUID provided as the PK, then create one now
  IF new.GUID = '#NONE#' THEN
    SET new.GUID = UTIL_NEWID();
  END IF;
END
//


-- ----------------------------------------------------------------------------------------
DELIMITER //
CREATE TABLE MuseumTypes
(
	GUID CHAR(36) NOT NULL DEFAULT '#NONE#' PRIMARY KEY,
    ID SERIAL,
    CustodianFormID CHAR(36) NULL,
    Code VARCHAR(20) NULL,
    Name VARCHAR(100) NOT NULL UNIQUE,
    Description VARCHAR(2000) NULL,
    ScopingNote TEXT NULL
)
ENGINE=InnoDB COLLATE utf8_unicode_ci
//

DELIMITER //
CREATE TRIGGER MuseumTypes_TR_GUID
BEFORE INSERT ON MuseumTypes
FOR EACH ROW
BEGIN
-- if no GUID provided as the PK, then create one now
  IF new.GUID = '#NONE#' THEN
    SET new.GUID = UTIL_NEWID();
  END IF;
END
//


-- ----------------------------------------------------------------------------------------
DELIMITER //
CREATE TABLE Museums
(
	GUID CHAR(36) NOT NULL DEFAULT '#NONE#' PRIMARY KEY,
    ID SERIAL,
    MuseumTypeID CHAR(36) NULL,
    ParentID CHAR(36) NULL,
    Code VARCHAR(20) NULL,
    Name VARCHAR(200) NOT NULL,
    Description VARCHAR(2000) NULL,
    CountryID CHAR(36) NULL,
    NamedPlaceID CHAR(36) NULL,
    NamedPlace CHAR(255) NULL,
    GPS VARCHAR(200) NULL,
    HasNaturalHistory BOOLEAN DEFAULT 0,
    HasCulturalHistory BOOLEAN DEFAULT 0,
    HasMilitaryHistory BOOLEAN DEFAULT 0,
    HasSocialHistory BOOLEAN DEFAULT 0,
    HasLibrary BOOLEAN DEFAULT 0,
    HasArchives BOOLEAN DEFAULT 0,
    HasDigital BOOLEAN DEFAULT 0,
    Keywords VARCHAR(1000),
    Content TEXT NULL
)
ENGINE=InnoDB COLLATE utf8_unicode_ci
COMMENT ''
//

-- ALTER TABLE Museums
-- ADD Content TEXT NULL

/*
ALTER TABLE Museums
MODIFY GPS VARCHAR(200) NULL;
*/


DELIMITER //
CREATE TRIGGER Museums_TR_GUID
BEFORE INSERT ON Museums
FOR EACH ROW
BEGIN
  IF new.GUID = '#NONE#' THEN
    SET new.GUID = UTIL_NEWID();
  END IF;
END
//


-- ----------------------------------------------------------------------------------------
DELIMITER //
CREATE TABLE CollectionTypes
(
	GUID CHAR(36) NOT NULL DEFAULT '#NONE#' PRIMARY KEY,
    ID SERIAL,
    ParentID CHAR(36),
    Code VARCHAR(20) NULL,
    Name VARCHAR(50) NOT NULL UNIQUE,
    Keywords VARCHAR(1000) NULL,
    ScopingNote TEXT NULL
)
ENGINE=InnoDB COLLATE utf8_unicode_ci
COMMENT ''
//

DELIMITER //
CREATE TRIGGER CollectionTypes_TR_GUID
BEFORE INSERT ON CollectionTypes
FOR EACH ROW
BEGIN
  IF new.GUID = '#NONE#' THEN
    SET new.GUID = UTIL_NEWID();
  END IF;
END
//


-- ----------------------------------------------------------------------------------------
DELIMITER //
CREATE TABLE Collections
(
	GUID CHAR(36) NOT NULL DEFAULT '#NONE#' PRIMARY KEY,
    ID SERIAL,
    MuseumID CHAR(36),
    CollectionTypeID CHAR(36) NULL,
    Name VARCHAR(200) NOT NULL,
    Content TEXT NULL,
    Keywords VARCHAR(1000) NULL,
)
ENGINE=InnoDB COLLATE utf8_unicode_ci
COMMENT ''
//

-- ALTER TABLE Collections
-- CHANGE Description Content TEXT NULL


DELIMITER //
CREATE TRIGGER Collections_TR_GUID
BEFORE INSERT ON Collections
FOR EACH ROW
BEGIN
  IF new.GUID = '#NONE#' THEN
    SET new.GUID = UTIL_NEWID();
  END IF;
END
//


-- ----------------------------------------------------------------------------------------
DELIMITER //
CREATE TABLE ItemTypes
(
	GUID CHAR(36) NOT NULL DEFAULT '#NONE#' PRIMARY KEY,
    ID SERIAL,
    ParentID CHAR(36) NULL,
    Code VARCHAR(20) NULL,
    Name VARCHAR(100) NOT NULL UNIQUE,
    ScopingNote VARCHAR(2000) NULL,
    Seq VARCHAR(20) NULL
)
ENGINE=InnoDB COLLATE utf8_unicode_ci
COMMENT ''
//

DELIMITER //
CREATE TRIGGER ItemTypes_TR_GUID
BEFORE INSERT ON ItemTypes
FOR EACH ROW
BEGIN
  IF new.GUID = '#NONE#' THEN
    SET new.GUID = UTIL_NEWID();
  END IF;
END
//


-- ----------------------------------------------------------------------------------------
DELIMITER //
CREATE TABLE Items
(
	GUID CHAR(36) NOT NULL DEFAULT '#NONE#' PRIMARY KEY,
    ID SERIAL,
    CollectionID CHAR(36) NOT NULL,
    ItemTypeID CHAR(36) NULL ,
    ItemType VARCHAR(100) NULL,
    ItemNumber VARCHAR(100) NOT NULL, 
    Name VARCHAR(200),
    Description VARCHAR(200) NULL,
    Content TEXT NULL,
    Keywords VARCHAR(1000) NULL,
    Dimensions VARCHAR(50) NULL
		COMMENT 'What are the dimensions of this item',
    Materials VARCHAR(50) NULL
		COMMENT 'What materials is this item constructed from'
)
ENGINE=InnoDB COLLATE utf8_unicode_ci
COMMENT ''
//

-- ALTER TABLE Items
-- CHANGE LongDescription Content TEXT NULL

DELIMITER //
CREATE TRIGGER Items_TR_GUID
BEFORE INSERT ON Items
FOR EACH ROW
BEGIN
  IF new.GUID = '#NONE#' THEN
    SET new.GUID = UTIL_NEWID();
  END IF;
END
//

-- ----------------------------------------------------------------------------------------
DELIMITER //
CREATE TABLE ExhibitionTypes
(
	GUID CHAR(36) NOT NULL DEFAULT '#NONE#' PRIMARY KEY,
    ID SERIAL,
    ParentID CHAR(36) NULL,
    Code VARCHAR(5) NULL,
    Name VARCHAR(100) NOT NULL UNIQUE,
    ScopingNote VARCHAR(2000) NULL
)
ENGINE=InnoDB COLLATE utf8_unicode_ci
COMMENT ''
//

DELIMITER //
CREATE TRIGGER ExhibitionTypes_TR_GUID
BEFORE INSERT ON ExhibitionTypes
FOR EACH ROW
BEGIN
  IF new.GUID = '#NONE#' THEN
    SET new.GUID = UTIL_NEWID();
  END IF;
END
//


-- ----------------------------------------------------------------------------------------
DELIMITER //
CREATE TABLE Exhibitions
(
	GUID CHAR(36) NOT NULL DEFAULT '#NONE#' PRIMARY KEY,
    ID SERIAL,
    MuseumID CHAR(36) NOT NULL,
    ExhibitionTypeID CHAR(36) NULL,
    ExhibitionType VARCHAR(100) NULL,
    Code VARCHAR(20) NULL,
    Name VARCHAR(200) NOT NULL UNIQUE,
    IsVirtual BIT NOT NULL DEFAULT 0,
    DateDescription VARCHAR(100) NULL,
    DateMin BIGINT NULL,
    DateMax BIGINT NULL,
    Description VARCHAR(200) NULL,
    Content TEXT NULL,
    Keywords VARCHAR(1000) NULL
)
ENGINE=InnoDB COLLATE utf8_unicode_ci
COMMENT ''
//

-- ALTER TABLE Exhibitions
-- CHANGE LongDescription Content TEXT NULL

DELIMITER //
CREATE TRIGGER Exhibitions_TR_GUID
BEFORE INSERT ON Exhibitions
FOR EACH ROW
BEGIN
  IF new.GUID = '#NONE#' THEN
    SET new.GUID = UTIL_NEWID();
  END IF;
END
//

-- ----------------------------------------------------------------------------------------
DELIMITER //
CREATE TABLE StoryTypes
(
	GUID CHAR(36) NOT NULL DEFAULT '#NONE#' PRIMARY KEY,
    ID SERIAL,
    ParentID CHAR(36) NULL,
    Code VARCHAR(5) NULL,
    Name VARCHAR(100) NOT NULL UNIQUE,
    ScopingNote VARCHAR(2000) NULL
)
ENGINE=InnoDB COLLATE utf8_unicode_ci
COMMENT ''
//

DELIMITER //
CREATE TRIGGER StoryTypes_TR_GUID
BEFORE INSERT ON StoryTypes
FOR EACH ROW
BEGIN
  IF new.GUID = '#NONE#' THEN
    SET new.GUID = UTIL_NEWID();
  END IF;
END
//


-- ----------------------------------------------------------------------------------------
DELIMITER //
CREATE TABLE Stories
(
	GUID CHAR(36) NOT NULL DEFAULT '#NONE#' PRIMARY KEY,
    ID SERIAL,
    MuseumID CHAR(36) NOT NULL,
    StoryTypeID CHAR(36) NULL,
    StoryType VARCHAR(100) NULL,
    Code VARCHAR(100) NOT NULL, 
    Name VARCHAR(200),
    Description VARCHAR(200) NULL,
    Content TEXT NULL,
    Keywords VARCHAR(1000) NULL
)
ENGINE=InnoDB COLLATE utf8_unicode_ci
COMMENT ''
//

-- ALTER TABLE Stories
-- CHANGE LongDescription Content TEXT NULL


DELIMITER //
CREATE TRIGGER Stories_TR_GUID
BEFORE INSERT ON Stories
FOR EACH ROW
BEGIN
  IF new.GUID = '#NONE#' THEN
    SET new.GUID = UTIL_NEWID();
  END IF;
END
//


-- ----------------------------------------------------------------------------------------
DELIMITER //
CREATE TABLE LessonTypes
(
	GUID CHAR(36) NOT NULL DEFAULT '#NONE#' PRIMARY KEY,
    ID SERIAL,
    ParentID CHAR(36) NULL,
    Code VARCHAR(5) NULL,
    Name VARCHAR(100) NOT NULL UNIQUE,
    ScopingNote VARCHAR(2000) NULL
)
ENGINE=InnoDB COLLATE utf8_unicode_ci
COMMENT ''
//

DELIMITER //
CREATE TRIGGER LessonTypes_TR_GUID
BEFORE INSERT ON LessonTypes
FOR EACH ROW
BEGIN
  IF new.GUID = '#NONE#' THEN
    SET new.GUID = UTIL_NEWID();
  END IF;
END
//


-- ----------------------------------------------------------------------------------------
DELIMITER //
CREATE TABLE Lessons
(
	GUID CHAR(36) NOT NULL DEFAULT '#NONE#' PRIMARY KEY,
    ID SERIAL,
    MuseumID CHAR(36) NOT NULL,
    LessonTypeID CHAR(36) NULL,
    Lessontype VARCHAR(100) NULL,
    Code VARCHAR(20) NOT NULL, 
    Name VARCHAR(200) NOT NULL,
    Description TEXT NULL,
    Content TEXT NULL,
    CurriculumSubjectID CHAR(36),
    CurriculumElementID CHAR(36),
    Keywords VARCHAR(1000) NULL,
    InputFileID CHAR(36) NULL
)
ENGINE=InnoDB COLLATE utf8_unicode_ci
COMMENT ''
//

-- ALTER TABLE LEssons
-- ADD InputFileID CHAR(36) NULL;

-- ALTER TABLE Lessons
-- CHANGE LongDescription Content TEXT NULL

-- ALTER TABLE Lessons
-- MODIFY Code VARCHAR(20) NULL

-- ALTER TABLE Lessons
-- ADD CurriculumSubjectID CHAR(36) NULL AFTER Content;

-- ALTER TABLE Lessons
-- ADD CurriculumElementID CHAR(36) NULL AFTER CurriculumSubjectID;


DELIMITER //
CREATE TRIGGER Lessons_TR_GUID
BEFORE INSERT ON Lessons
FOR EACH ROW
BEGIN
  IF new.GUID = '#NONE#' THEN
    SET new.GUID = UTIL_NEWID();
  END IF;
END
//


-- ----------------------------------------------------------------------------------------
DELIMITER //
CREATE TABLE PublicationTypes
(
	GUID CHAR(36) NOT NULL DEFAULT '#NONE#' PRIMARY KEY,
    ID SERIAL,
    Code VARCHAR(5) NULL,
    Name VARCHAR(100) NOT NULL UNIQUE,
    ScopingNote TEXT NULL
)
ENGINE=InnoDB COLLATE utf8_unicode_ci
COMMENT ''
//

DELIMITER //
CREATE TRIGGER PublicationTypes_TR_GUID
BEFORE INSERT ON PublicationTypes
FOR EACH ROW
BEGIN
  IF new.GUID = '#NONE#' THEN
    SET new.GUID = UTIL_NEWID();
  END IF;
END
//


-- ----------------------------------------------------------------------------------------
DELIMITER //
CREATE TABLE Publications
(
	GUID CHAR(36) NOT NULL DEFAULT '#NONE#' PRIMARY KEY,
    ID SERIAL,
    MuseumID CHAR(36) NOT NULL,
    PublicationTypeID CHAR(36) NULL,
    PublicationType VARCHAR(50) NULL,
    Title VARCHAR(200) NOT NULL, 
    Authors VARCHAR(200) NULL,
    Abstract TEXT NULL,
    Citation VARCHAR(255) NULL,
    DateDescription VARCHAR(100) NULL,
    DateMin BIGINT NULL,
    DateMax BIGINT NULL,
    Content TEXT NULL
)
ENGINE=InnoDB COLLATE utf8_unicode_ci
COMMENT 'Publications produced by the museum'
//

-- ALTER TABLE Publications
-- ADD Content TEXT NULL

DELIMITER //
CREATE TRIGGER Publications_TR_GUID
BEFORE INSERT ON Publications
FOR EACH ROW
BEGIN
  IF new.GUID = '#NONE#' THEN
    SET new.GUID = UTIL_NEWID();
  END IF;
END
//


-- ----------------------------------------------------------------------------------------
DELIMITER //
CREATE TABLE Biographies
(
	GUID CHAR(36) NOT NULL DEFAULT '#NONE#' PRIMARY KEY,
    ID SERIAL,
    MuseumID CHAR(36) NOT NULL
		COMMENT 'Which museu contributed this biography',
    PerOrgID CHAR(36) NOT NULL
		COMMENT 'Which person / organisation is this about',
	Name VARCHAR(100) NOT NULL,
    Title VARCHAR(200) NULL,
	BiographyFormat VARCHAR(20) NULL
		COMMENT 'The format of the Biography',
	Content TEXT NOT NULL
		COMMENT 'The biography itself, in SDF format or MD',
    Note TEXT NULL
)
ENGINE=InnoDB COLLATE utf8_unicode_ci
COMMENT ''
//

-- ALTER TABLE Biographies
-- CHANGE Biography Content TEXT NULL


DELIMITER //
CREATE TRIGGER Biographies_TR_GUID
BEFORE INSERT ON Biographies
FOR EACH ROW
BEGIN
  IF new.GUID = '#NONE#' THEN
    SET new.GUID = UTIL_NEWID();
  END IF;
END
//


-- ----------------------------------------------------------------------------------------
DELIMITER //
CREATE TABLE MuseumEventTypes
(
	GUID CHAR(36) NOT NULL DEFAULT '#NONE#' PRIMARY KEY,
    ID SERIAL,
    Code VARCHAR(5) NULL,
    Name VARCHAR(100) NOT NULL UNIQUE,
    ScopingNote TEXT NULL
)
ENGINE=InnoDB COLLATE utf8_unicode_ci
COMMENT ''
//

DELIMITER //
CREATE TRIGGER MuseumEventTypes_TR_GUID
BEFORE INSERT ON MuseumEventTypes
FOR EACH ROW
BEGIN
  IF new.GUID = '#NONE#' THEN
    SET new.GUID = UTIL_NEWID();
  END IF;
END
//

-- ----------------------------------------------------------------------------------------
DELIMITER //
CREATE TABLE MuseumEvents
(
	GUID CHAR(36) NOT NULL DEFAULT '#NONE#' PRIMARY KEY,
    ID SERIAL,
    MuseumID CHAR(36) NOT NULL,
    MuseumEventTypeID CHAR(36) NULL,
    MuseumEventType VARCHAR(50) NULL,
    Title VARCHAR(200) NOT NULL, 
    Content TEXT NULL,
    DateDescription VARCHAR(100) NULL,
    DateMin BIGINT NULL,
    DateMax BIGINT NULL
)
ENGINE=InnoDB COLLATE utf8_unicode_ci
COMMENT 'Publications produced by the museum'
//

-- ALTER TABLE MuseumEvents
-- CHANGE Description Content TEXT NULL

DELIMITER //
CREATE TRIGGER MuseumEvents_TR_GUID
BEFORE INSERT ON MuseumEvents
FOR EACH ROW
BEGIN
  IF new.GUID = '#NONE#' THEN
    SET new.GUID = UTIL_NEWID();
  END IF;
END
//


-- ----------------------------------------------------------------------------------------
DELIMITER //
CREATE TABLE Experts
(
	GUID CHAR(36) NOT NULL DEFAULT '#NONE#' PRIMARY KEY,
    ID SERIAL,
    MuseumID CHAR(36) NULL
		COMMENT 'Expert may not be associated with a museum',
    PerOrgID CHAR(36) NULL,
	PerOrg VARCHAR(100) NULL,
    SpecialtyAreas VARCHAR(255) NULL,
    Content TEXT NULL
)
ENGINE=InnoDB COLLATE utf8_unicode_ci
COMMENT 'Publications produced by the museum'
//

-- ALTER TABLE Experts
-- ADD  Content TEXT NULL

DELIMITER //
CREATE TRIGGER Experts_TR_GUID
BEFORE INSERT ON Experts
FOR EACH ROW
BEGIN
  IF new.GUID = '#NONE#' THEN
    SET new.GUID = UTIL_NEWID();
  END IF;
END
//


-- ----------------------------------------------------------------------------------------
DELIMITER //
CREATE TABLE DigitalFormats
(
	GUID CHAR(36) NOT NULL DEFAULT '#NONE#' PRIMARY KEY,
    ID SERIAL,
    Code VARCHAR(5) NULL,
    Name VARCHAR(100) NOT NULL UNIQUE,
    MIME VARCHAR(50) NULL,
    ScopingNote VARCHAR(2000) NULL
)
ENGINE=InnoDB COLLATE utf8_unicode_ci 
//

DELIMITER //
CREATE TRIGGER DigitalFormats_TR_GUID
BEFORE INSERT ON DigitalFormats
FOR EACH ROW
BEGIN
-- if no GUID provided as the PK, then create one now
  IF new.GUID = '#NONE#' THEN
    SET new.GUID = UTIL_NEWID();
  END IF;
END
//
    

-- ----------------------------------------------------------------------------------------
DELIMITER //
CREATE TABLE DigitalRepositories
(
	GUID CHAR(36) NOT NULL DEFAULT '#NONE#' PRIMARY KEY,
    ID SERIAL,
    CustodianID CHAR(36) NULL,
    MuseumID CHAR(36) NULL,
    Code CHAR(20) NULL,
    Name CHAR(50) NULL,
    Address CHAR(200) NULL,
    Note TEXT NOT NULL
)
ENGINE=InnoDB COLLATE utf8_unicode_ci
//

DELIMITER //
CREATE TRIGGER DigitalRepositories_TR_GUID
BEFORE INSERT ON DigitalRepositories
FOR EACH ROW
BEGIN
-- if no GUID provided as the PK, then create one now
  IF new.GUID = '#NONE#' THEN
    SET new.GUID = UTIL_NEWID();
  END IF;
END
//


-- ----------------------------------------------------------------------------------------
DELIMITER //
CREATE TABLE DigitalFolders
(
	GUID CHAR(36) NOT NULL DEFAULT '#NONE#' PRIMARY KEY,
    ID SERIAL,
    DigitalRepositoryID CHAR(36) NULL,
    ParentID CHAR(36) NULL,
    Name VARCHAR(50) NULL,
    Description VARCHAR(2000) NULL,
    Note TEXT NULL
)
ENGINE=InnoDB COLLATE utf8_unicode_ci
//

DELIMITER //
CREATE TRIGGER DigitalFolders_TR_GUID
BEFORE INSERT ON DigitalFolders
FOR EACH ROW
BEGIN
-- if no GUID provided as the PK, then create one now
  IF new.GUID = '#NONE#' THEN
    SET new.GUID = UTIL_NEWID();
  END IF;
END
//


-- ----------------------------------------------------------------------------------------
DELIMITER //
CREATE TABLE DigitalObjects
(
	GUID CHAR(36) NOT NULL DEFAULT '#NONE#' PRIMARY KEY,
    ID SERIAL,
    RefETID INT NULL,
    RefGUID CHAR(36) NOT NULL,
    DigitalFolderID CHAR(36) NULL,
    DigitalFormatID CHAR(36) NULL,
    ParentID CHAR(36) NULL,
    FileName VARCHAR(50) NULL,
    Description VARCHAR(2000) NULL,
    Note TEXT NULL
)
ENGINE=InnoDB COLLATE utf8_unicode_ci
//

DELIMITER //
CREATE TRIGGER DigitalObjects_TR_GUID
BEFORE INSERT ON DigitalObjects
FOR EACH ROW
BEGIN
-- if no GUID provided as the PK, then create one now
  IF new.GUID = '#NONE#' THEN
    SET new.GUID = UTIL_NEWID();
  END IF;
END
//

/*
ALTER TABLE DigitalObjects
MODIFY FileName VARCHAR(255) NOT NULL;

ALTER TABLE DigitalObjects
MODIFY Note TEXT NULL;
*/

-- ----------------------------------------------------------------------------------------
DELIMITER //
CREATE TABLE DigitalObjectLinks
(
	GUID CHAR(36) NOT NULL DEFAULT '#NONE#' PRIMARY KEY,
    ID SERIAL,
    RefETID INT NULL,
    RefGUID CHAR(36) NOT NULL,
    DigitalObjectID CHAR(36) NULL
)
ENGINE=InnoDB COLLATE utf8_unicode_ci
//

DELIMITER //
CREATE TRIGGER DigitalObjectLinks_TR_GUID
BEFORE INSERT ON DigitalObjectLinks
FOR EACH ROW
BEGIN
-- if no GUID provided as the PK, then create one now
  IF new.GUID = '#NONE#' THEN
    SET new.GUID = UTIL_NEWID();
  END IF;
END
//


-- ----------------------------------------------------------------------------------------
-- InputFiles = the sequence in which the files were loaded and ingested
-- ID = the sequence number of the receipt of the file, which is then moved 
-- 		to the ingest buffer to be checked before full ingestion
-- ----------------------------------------------------------------------------------------
DELIMITER //
CREATE TABLE InputFiles
(
	GUID CHAR(36) NOT NULL DEFAULT '#NONE#' PRIMARY KEY,
    ID SERIAL,
    UserID CHAR(36) NOT NULL, -- must always be a valid user who contributes this data
    FileName VARCHAR(255) NOT NULL,
    MuseumID CHAR(36) NULL,
    Museum VARCHAR(255) NULL,
    DateStarted DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    DateEnded DATETIME NULL,
    NumLines INT DEFAULT 0,
    NumErrors INT DEFAULT 0,
    Content TEXT NULL,
    Status INT NOT NULL DEFAULT 0
    
)
ENGINE=InnoDB COLLATE utf8_unicode_ci
COMMENT ''
//

/*
ALTER TABLE InputFiles
ADD Content TEXT NULL;


ALTER TABLE InputFiles
MODIFY `MuseumID` CHAR(36) NULL;

ALTER TABLE InputFiles
ADD Status INT NOT NULL DEFAULT 0;

ALTER TABLE InputFiles
ADD Museum VARCHAR(255) NOT NULL AFTER MuseumID;

ALTER TABLE InputFiles
ADD UserID CHAR(36) NOT NULL AFTER ID;

ALTER TABLE InputFiles
ADD FOREIGN KEY (UserID) REFERENCES Users (GUID);


*/

DELIMITER //
CREATE TRIGGER InputFiles_TR_GUID
BEFORE INSERT ON InputFiles
FOR EACH ROW
BEGIN
  IF new.GUID = '#NONE#' THEN
    SET new.GUID = UTIL_NEWID();
  END IF;
END
//



DELIMITER //
CREATE TABLE InputFileLines
(
	GUID CHAR(36) NOT NULL DEFAULT '#NONE#' PRIMARY KEY,
    ID SERIAL,
    InputFileID CHAR(36) NOT NULL,
    LineStart INT NOT NULL,
    LineEnd INT NOT NULL,
    CommandNum INT NOT NULL,
    Command VARCHAR(2000) NOT NULL, -- the file line
    ErrorCode VARCHAR(10) NULL,
    Error VARCHAR(255) NULL
)
ENGINE=InnoDB COLLATE utf8_unicode_ci
COMMENT ''
//

DELIMITER //
CREATE TRIGGER InputFileLines_TR_GUID
BEFORE INSERT ON InputFileLines
FOR EACH ROW
BEGIN
  IF new.GUID = '#NONE#' THEN
    SET new.GUID = UTIL_NEWID();
  END IF;
END
//
