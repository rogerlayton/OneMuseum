/*
** ONE-MUSEUM.COM
** SCRIPT: ONE-MUSEUM-003.SQL : FOREIGN KEYS and INDEXES
**
** The FKs are added after the table creation (001) and the data setup (002)
** since the data in hierarchical tables does not then need to be sequenced
** from top to bottom, which is non-trivial.
**
** NOTE: FK constraints will automatically create an INDEX on the table.field
*/

USE onemuseum;

-- 010 : EntityTypes

-- 020 : UserTypes

-- 021 : SecretQuesstions

-- 025 : Users

CREATE INDEX IN_Users_Email ON Users(Email);

ALTER TABLE Users
ADD FOREIGN KEY (UserRoleTypeID) REFERENCES UserRoleTypes (GUID);

ALTER TABLE Users
ADD FOREIGN KEY (NamedPlaceID) REFERENCES NamedPlaces (GUID);

-- 026 : UserSecretQuestions

ALTER TABLE UserSecretQuestions
ADD FOREIGN KEY (UserID) REFERENCES Users (GUID);

ALTER TABLE UserSecretQuestions
ADD FOREIGN KEY (SecretQuestionID) REFERENCES SecretQuestions (GUID);

-- 031 : UserFolders

ALTER TABLE UserFolders
ADD FOREIGN KEY (UserID) REFERENCES Users (GUID);

ALTER TABLE UserFolders
ADD FOREIGN KEY (ParentID) REFERENCES UserFolders (GUID);

-- 032 : UserEntities

ALTER TABLE UserEntities
ADD FOREIGN KEY (RefETID) REFERENCES EntityTypes (ETID);

ALTER TABLE UserEntities
ADD FOREIGN KEY (UserID) REFERENCES Users (GUID);

ALTER TABLE UserEntities
ADD FOREIGN KEY (UserFolderID) REFERENCES UserFolders (GUID);

-- 041 : UserNoteTypes

-- 045 : UserNotes

ALTER TABLE UserNotes
ADD FOREIGN KEY (UserNoteTypeID) REFERENCES UserNoteTypes (GUID);

ALTER TABLE UserNotes
ADD FOREIGN KEY (RefETID) REFERENCES ENtityTypes (ETID);

-- 051 : UserFilters

ALTER TABLE UserFilters
ADD FOREIGN KEY (UserID) REFERENCES Users (GUID);

ALTER TABLE UserFilters
ADD FOREIGN KEY (CategoryETID) REFERENCES ENtityTypes (ETID);



-- 055 : UserFilterValues

ALTER TABLE UserFilterValues
ADD FOREIGN KEY (UserFilterID) REFERENCES UserFilters (GUID);


-- 051 : UserNoteTypes

-- 052 : UserNotes

ALTER TABLE UserNotes
ADD FOREIGN KEY (UserID) REFERENCES Users (GUID);

ALTER TABLE UserNotes
ADD FOREIGN KEY (UserNoteTypeID) REFERENCES UserNoteTypes (GUID);

ALTER TABLE UserNotes
ADD FOREIGN KEY (RefETID) REFERENCES EntityTypes (ETID);

-- 071 : Sessions

ALTER TABLE Sessions
ADD FOREIGN KEY (UserID) REFERENCES Users (GUID);

-- 072 : SessionData

ALTER TABLE SessionData
ADD FOREIGN KEY (SessionID) REFERENCES Sessions (GUID);

ALTER TABLE SessionData
ADD FOREIGN KEY (RefETID) REFERENCES EntityTypes (ETID);

-- 081 : Communities

CREATE INDEX IN_Communities_Name ON Communities(Name);

-- 085 : CommunityMembers

ALTER TABLE CommunityMembers
ADD FOREIGN KEY (CommunityID) REFERENCES Communities (GUID);

ALTER TABLE CommunityMembers
ADD FOREIGN KEY (UserID) REFERENCES Users (GUID);

-- 091 : Posts

ALTER TABLE Posts
ADD FOREIGN KEY (UserID) REFERENCES Users (GUID);
 
-- 101 : NamedPlaceTypes

ALTER TABLE NamedPlaceTypes
ADD FOREIGN KEY (ParentID) REFERENCES NamedPlaceTypes (GUID);

-- 105 : NamedPlaces

ALTER TABLE NamedPlaces
ADD FOREIGN KEY (NamedPlaceTypeID) REFERENCES NamedPlaceTypes (GUID);

ALTER TABLE NamedPlaces
ADD FOREIGN KEY (ParentID) REFERENCES NamedPlaces (GUID);

ALTER TABLE NamedPlaces
ADD FOREIGN KEY (MunicipalityID) REFERENCES NamedPlaces (GUID);

ALTER TABLE NamedPlaces
ADD FOREIGN KEY (ProvinceID) REFERENCES NamedPlaces (GUID);

ALTER TABLE NamedPlaces
ADD FOREIGN KEY (CountryID) REFERENCES NamedPlaces (GUID);

-- 101 : NamedEventTypes

ALTER TABLE NamedEventTypes
ADD FOREIGN KEY (ParentID) REFERENCES NamedEventTypes (GUID);

-- 115 : NamedEvents

ALTER TABLE NamedEvents
ADD FOREIGN KEY (NamedEventTypeID) REFERENCES NamedEventTypes (GUID);

ALTER TABLE NamedEvents
ADD FOREIGN KEY (ParentID) REFERENCES NamedEvents (GUID);

ALTER TABLE NamedEvents
ADD FOREIGN KEY (CountryID) REFERENCES Countries(GUID);


-- 121 : PerOrgTypes

ALTER TABLE PerOrgTypes
ADD FOREIGN KEY (ParentID) REFERENCES PerOrgTypes (GUID);

-- 122 : PerOrgLinkTypes

ALTER TABLE PerOrgLinkTypes
ADD FOREIGN KEY (ParentID) REFERENCES PerOrgLinkTypes (GUID);

-- 125 : PerOrgs

ALTER TABLE PerOrgs
ADD FOREIGN KEY (PerOrgTypeID) REFERENCES PerOrgTypes (GUID);

-- 126 : PerOrgLinks

ALTER TABLE PerOrgLinks
ADD FOREIGN KEY (PerOrgFromID) REFERENCES PerOrgs (GUID);

ALTER TABLE PerOrgLinks
ADD FOREIGN KEY (PerOrgToID) REFERENCES PerOrgs (GUID);

ALTER TABLE PerOrgLinks
ADD FOREIGN KEY (PerOrgLinkTypeID) REFERENCES PerOrgLinkTypes (GUID);

-- 131 : ChenhallNomenclature

ALTER TABLE ChenhallNomenclature
ADD FOREIGN KEY (ParentID) REFERENCES ChenhallNomenclature (ID);

-- 141 : Subjects

ALTER TABLE Subjects
ADD FOREIGN KEY (ParentID) REFERENCES Subjects (GUID);

-- 151 : Curricula

ALTER TABLE Curricula
ADD FOREIGN KEY (NamedPlaceID) REFERENCES NamedPlaces (GUID);

-- 152 : CurriculumSubjects

ALTER TABLE CurriculumSubjects
ADD FOREIGN KEY (ParentID) REFERENCES CurriculumSubjects (GUID);

ALTER TABLE CurriculumSubjects
ADD FOREIGN KEY (CurriculumID) REFERENCES Curricula (GUID);

-- 153 : CurriculumLevels

ALTER TABLE CurriculumLevels
ADD FOREIGN KEY (ParentID) REFERENCES CurriculumLevels (GUID);

ALTER TABLE CurriculumLevels
ADD FOREIGN KEY (CurriculumID) REFERENCES Curricula (GUID);

-- 155 : CurriculumElements

ALTER TABLE CurriculumElements
ADD FOREIGN KEY (ParentID) REFERENCES CurriculumElements (GUID);

ALTER TABLE CurriculumElements
ADD FOREIGN KEY (CurriculumID) REFERENCES Curricula (GUID);

ALTER TABLE CurriculumElements
ADD FOREIGN KEY (CurriculumSubjectID) REFERENCES CurriculumSubjects (GUID);

ALTER TABLE CurriculumElements
ADD FOREIGN KEY (CurriculumLevelID) REFERENCES CurriculumLevels (GUID);

-- 201 : NameTypes

ALTER TABLE NameTypes
ADD FOREIGN KEY (ParentID) REFERENCES NameTypes (GUID);

ALTER TABLE NameTypes
ADD FOREIGN KEY (AppliesTo) REFERENCES EntityTypes (ETID);

-- 202 : Names

ALTER TABLE Names
ADD FOREIGN KEY (RefETID) REFERENCES EntityTypes (ETID);

ALTER TABLE Names
ADD FOREIGN KEY (NameTypeID) REFERENCES NameTypes (GUID);

CREATE INDEX IN_Names_RefGUID ON Names (RefGUID);
CREATE INDEX IN_Names_Name ON Names (Name);

-- 211 : NoteTypes

ALTER TABLE NoteTypes
ADD FOREIGN KEY (ParentID) REFERENCES NoteTypes (GUID);

ALTER TABLE NoteTypes
ADD FOREIGN KEY (AppliesTo) REFERENCES EntityTypes (ETID);

-- 212 : Notes

ALTER TABLE Notes
ADD FOREIGN KEY (RefETID) REFERENCES EntityTypes (ETID);

ALTER TABLE Notes
ADD FOREIGN KEY (NoteTypeID) REFERENCES NoteTypes (GUID);

CREATE INDEX IN_Notes_RefGUID ON Notes (RefGUID);

-- 221 : IdentifierTypes

ALTER TABLE IdentifierTypes
ADD FOREIGN KEY (ParentID) REFERENCES IdentifierTypes (GUID);

ALTER TABLE IdentifierTypes
ADD FOREIGN KEY (AppliesTo) REFERENCES EntityTypes (ETID);

-- 222 : Identifiers

ALTER TABLE Identifiers
ADD FOREIGN KEY (RefETID) REFERENCES EntityTypes (ETID);

ALTER TABLE Identifiers
ADD FOREIGN KEY (IdentifierTypeID) REFERENCES IdentifierTypes (GUID);

CREATE INDEX IN_Identifiers_RefGUID ON Identifiers (RefGUID);
CREATE INDEX IN_Identifiers_Identifier ON Identifiers (Identifier);

-- 241 : RoleTypes

ALTER TABLE RoleTypes
ADD FOREIGN KEY (ParentID) REFERENCES RoleTypes (GUID);

ALTER TABLE RoleTypes
ADD FOREIGN KEY (AppliesTo) REFERENCES EntityTypes (ETID);

-- 242 : Roles

ALTER TABLE Roles
ADD FOREIGN KEY (RefETID) REFERENCES EntityTypes (ETID);

ALTER TABLE Roles
ADD FOREIGN KEY (RoleTypeID) REFERENCES RoleTypes (GUID);

CREATE INDEX IN_Roles_RefGUID ON Roles (RefGUID);

-- 251 : EventTypes

ALTER TABLE EventTypes
ADD FOREIGN KEY (ParentID) REFERENCES EventTypes (GUID);

ALTER TABLE EventTypes
ADD FOREIGN KEY (AppliesTo) REFERENCES EntityTypes (ETID);

-- 252 : Roles

ALTER TABLE Events
ADD FOREIGN KEY (RefETID) REFERENCES EntityTypes (ETID);

ALTER TABLE Events
ADD FOREIGN KEY (EventTypeID) REFERENCES EventTypes (GUID);

CREATE INDEX IN_Events_RefGUID ON Events (RefGUID);

-- 273 : Categorizations

ALTER TABLE Categorizations
ADD FOREIGN KEY (RefETID) REFERENCES EntityTypes (ETID);

-- 511 : MuseumTypes
-- 512 : MuseumsForms

-- 515 : Museums

ALTER TABLE Museums
ADD FOREIGN KEY (MuseumTypeID) REFERENCES MuseumTypes (GUID);

ALTER TABLE Museums
ADD FOREIGN KEY (ParentID) REFERENCES Museums (GUID);

CREATE INDEX IN_Museums_Name ON Museums(Name);

-- 521 : CollectionTypes

ALTER TABLE CollectionTypes
ADD FOREIGN KEY (ParentID) REFERENCES CollectionTypes (GUID);

-- 525 : Collections

ALTER TABLE Collections
ADD FOREIGN KEY (CollectionTypeID) REFERENCES CollectionTypes (GUID);

ALTER TABLE Collections
ADD FOREIGN KEY (MuseumID) REFERENCES Museums (GUID);

-- 531 : ItemTypes

ALTER TABLE ItemTypes
ADD FOREIGN KEY (ParentID) REFERENCES ItemTypes (GUID);

-- 535 : Items

ALTER TABLE Items
ADD FOREIGN KEY (ItemTypeID) REFERENCES ItemTypes (GUID);

ALTER TABLE Items
ADD FOREIGN KEY (CollectionID) REFERENCES Collections (GUID);

-- 541 : ExhibitionTypes

ALTER TABLE ExhibitionTypes
ADD FOREIGN KEY (ParentID) REFERENCES ExhibitionTypes (GUID);

-- 545 : Exhibitions

ALTER TABLE Exhibitions
ADD FOREIGN KEY (MuseumID) REFERENCES Museums (GUID);

ALTER TABLE Exhibitions
ADD FOREIGN KEY (ExhibitionTypeID) REFERENCES ExhibitionTypes (GUID);

-- 551 : StoryTypes

ALTER TABLE StoryTypes
ADD FOREIGN KEY (ParentID) REFERENCES StoryTypes (GUID);

-- 555 : Stories

ALTER TABLE Stories
ADD FOREIGN KEY (MuseumID) REFERENCES Museums (GUID);

ALTER TABLE Stories
ADD FOREIGN KEY (StoryTypeID) REFERENCES StoryTypes (GUID);

-- 561 : LessonTypes

-- 565 : Lessons

ALTER TABLE Lessons
ADD FOREIGN KEY (MuseumID) REFERENCES Museums (GUID);

ALTER TABLE Lessons
ADD FOREIGN KEY (LessonTypeID) REFERENCES LessonTypes (GUID);


-- 571 : PublicationTypes

-- 575 : Publications

ALTER TABLE Publications
ADD FOREIGN KEY (MuseumID) REFERENCES Museums (GUID);

ALTER TABLE Publications
ADD FOREIGN KEY (PublicationTypeID) REFERENCES PublicationTypes (GUID);


-- 810 : Input Files

ALTER TABLE InputFiles
ADD FOREIGN KEY (MuseumID) REFERENCES Museums (GUID);

-- 820 : InputFileLines

ALTER TABLE InputFileLines
ADD FOREIGN KEY (InputFileID) REFERENCES InputFiles (GUID);


SET SQL_SAFE_UPDATES = 0;
UPDATE ChenhallNomenclature SET ParentID = null WHERE ParentID = 0;
UPDATE RoleTypes SET AppliesTo = null WHERE APpliesTo = 0;
ALTER TABLE ChenhallNomenclature
ADD FOREIGN KEY (ParentID) REFERENCES ChenhallNomenclature (ID);

ALTER TABLE RoleTypes
ADD FOREIGN KEY (AppliesTo) REFERENCES EntityTypes (ETID);
SET SQL_SAFE_UPDATES = 1;
