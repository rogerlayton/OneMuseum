/*
** ONE-MUSEUM.COM
** SCRIPT: ONE-MUSEUM-005.SQL : VIEWS
** 
** DETAILS VIEWS: used in the genDetails template
**
** First three fields: entity type name, entity name, entity guid
** Last two fields: user id, star (if this is in user favourites for this user)
**
** These must be used by including UserID and EntityGUID into the WHERE clause
** and also using LIMIT 1 to ensure that only 1 is selected (should always be the case) 
*/


USE OneMuseum;

-- =========================================================================
-- DETAILS VIEWS
-- =========================================================================


-- -------------------------------------------------------------------------
-- ENTITY DETAILS
-- -------------------------------------------------------------------------

DELIMITER ;
DROP VIEW IF EXISTS MuseumDetails;
CREATE VIEW MuseumDetails
AS
	SELECT
		'Museum' AS EntityType,
		m.Name AS Name,
		m.GUID AS GUID,
		m.Code AS Code,
		mt.Name AS Type,
        c.Name AS Country,
   		u.GUID AS UserID,
        IsUserFavourite(u.guid, m.GUID) AS Star,
        IFNULL(m.Content, ' ') As Content
    FROM Museums m
    CROSS JOIN Users u
	LEFT JOIN MuseumTypes mt ON m.MuseumTypeID = mt.GUID
    LEFT JOIN Countries c ON m.CountryID = c.GUID;
    
-- SELECT * FROM MuseumDetails;


DELIMITER  ;
DROP VIEW IF EXISTS CollectionDetails;
CREATE VIEW CollectionDetails
AS 
    SELECT
		'Collection' AS EntityType,
		c.Name AS Name,
		c.GUID AS GUID, 
	    m.Name AS Museum,
		ct.Name AS Type,
		u.GUID AS UserID,
        IsUserFavourite(u.guid, c.GUID) AS Star,
        IFNULL(c.Content, ' ') As Content
	FROM Collections c 
    CROSS JOIN Users u
	LEFT JOIN CollectionTypes ct ON c.CollectionTypeID = ct.GUID
    LEFT JOIN Museums m on c.MuseumID = m.GUID;

-- SELECT * FROM CollectionDetails;

USE OneMuseum;

DELIMITER ;
DROP VIEW IF EXISTS LessonDetails;
CREATE VIEW LessonDetails
AS 
	SELECT
		'Lesson' AS EntityType,
        l.Name AS Name,
		l.GUID as GUID,
        m.Name As Museum,
        l.Description AS Description,
        lt.Name AS Type,
		u.GUID AS UserID,
        IsUserFavourite(u.guid, l.GUID) AS Star,
        IFNULL(l.Content, ' ') As Content
    FROM Lessons l
	CROSS JOIN Users u
	LEFT JOIN Museums m on l.MuseumID = m.GUID
    LEFT JOIN LessonTypes lt ON l.LessonTypeID = lt.GUID;

-- SELECT * FROM LessonDetails ;


DELIMITER ;
DROP VIEW IF EXISTS ExhibitionDetails;
CREATE VIEW ExhibitionDetails
AS  
	SELECT
		'Exhibition' AS EntityType,
		e.Name AS Name,
		e.GUID AS GUID,
        m.Name AS Museum,
		et.Name AS Type,
		e.Description AS Description,
		u.GUID AS UserID,
        IsUserFavourite(u.guid, e.GUID) AS Star,
        IFNULL(e.Content, ' ') AS Content
	FROM Exhibitions e 
    CROSS JOIN Users u
	LEFT JOIN Museums m on e.MuseumID = m.GUID
    LEFT JOIN ExhibitionTypes et ON e.ExhibitionTypeID = et.GUID;
-- SELECT * FROM ExhibitionDetails;


DELIMITER ;
DROP VIEW IF EXISTS BiographyDetails;
CREATE VIEW BiographyDetails
AS
    SELECT
		'Biography' AS EntityType,
        p.Name As Name,
		b.GUID as GUID,
        b.Title AS Title,
		m.Name AS Museum,
		u.GUID AS UserID,
        IsUserFavourite(u.guid, b.GUID) AS Star,
        IFNULL(b.Content, ' ') AS Content
    FROM Biographies b
    CROSS JOIN Users u
	LEFT JOIN Museums m on b.MuseumID = m.GUID
    LEFT JOIN PerOrgs p on b.PerOrgID = p.GUID;		  
-- SELECT * FROM BiographyDetails;


DELIMITER ;
DROP VIEW IF EXISTS ExpertDetails;
CREATE VIEW ExpertDetails
AS 
	SELECT
		'Expert' AS EntityType,
        p.Name As Name,
		e.GUID AS GUID,
		e.specialtyAreas AS `Specialty Area`,
		u.GUID AS UserID,
        IsUserFavourite(u.guid, e.GUID) AS Star
    FROM Experts e
    CROSS JOIN Users u
	LEFT JOIN PerOrgs p ON e.PerOrgID = p.GUID;
-- SELECT * FROM ExpertDetails;


DELIMITER ;
DROP VIEW IF EXISTS ItemDetails;
CREATE VIEW ItemDetails
AS 
	SELECT
		'Item' AS EntityType,
        i.Name AS Name,
		i.GUID AS GUID,
		m.Name AS Museum,
		c.Name AS Collection,
		i.ItemNumber AS `Item Number`,
		i.Description,
        it.Name AS Type,
 		u.GUID AS UserID,
		IsUserFavourite(u.guid, i.GUID) AS Star
	FROM Items i 
	CROSS JOIN Users u
    LEFT JOIN ItemTypes it ON i.ItemTypeID = it.GUID
	LEFT JOIN Collections c ON i.CollectionID = c.GUID
	LEFT JOIN Museums m ON c.MuseumID = m.GUID;
-- SELECT * FROM ItemDetails;  


DELIMITER ;
DROP VIEW IF EXISTS MuseumEventDetails;
CREATE VIEW MuseumEventDetails
AS 
	SELECT
		'Museum Event' AS EntityType,
        me.Title AS Name,
		me.GUID AS GUID,
        m.Name As Museum,
        me.Content AS Content, 
        me.DateDescription AS Date,
        met.Name AS Type,
		u.GUID AS UserID,
        IsUserFavourite(u.guid, me.GUID) AS Star  
    FROM MuseumEvents me
    CROSS JOIN Users u
    LEFT JOIN Museums m on me.MuseumID = m.GUID
    LEFT JOIN MuseumEventTypes met ON me.MuseumEventTypeID = met.GUID;
-- SELECT * FROM MuseumEventDetails;  


DELIMITER ;
DROP VIEW IF EXISTS PublicationDetails;
CREATE VIEW PublicationDetails
AS 
	SELECT
		'Publication' AS EntityType,
        p.Title AS Name,
		p.GUID as GUID,
        p.Authors AS Authors,
        p.DateDescription AS Date,
        m.Name As Museum,
        pt.Name AS Type,
		u.GUID AS UserID,
        IsUserFavourite(u.guid, p.GUID) AS Star
    FROM Publications p
	CROSS JOIN Users u
    LEFT JOIN PublicationTypes pt ON p.PublicationTypeID = pt.GUID
    LEFT JOIN Museums m on p.MuseumID = m.GUID;
-- SELECT * FROM PublicationDetails;    


DELIMITER ;
DROP VIEW IF EXISTS StoryDetails;
CREATE VIEW StoryDetails
AS 
	SELECT
		'Story' AS EntityType,
        s.Name AS Name,
		s.GUID as guid,
        m.Name AS Museum,
        s.Description AS Description,
        st.Name AS Type,
        s.Keywords AS Keywords,
		u.GUID AS UserID,
        IsUserFavourite(u.guid, s.GUID) AS Star,
        IFNULL(s.Content,' ') AS Content
    FROM Stories s
    CROSS JOIN Users u
    LEFT JOIN Museums m on s.MuseumID = m.GUID
    LEFT JOIN StoryTypes st ON s.StoryTypeID = st.GUID;
-- SELECT * FROM StoryDetails;


-- -------------------------------------------------------------------------
-- ENTITY DETAILS
-- -------------------------------------------------------------------------


DELIMITER ;
DROP VIEW IF EXISTS NamedPlaceDetails;
CREATE VIEW NamedPlaceDetails
AS
	SELECT
		'Named Place' AS EntityType,
		np.Name AS Name,
		np.GUID AS GUID,
		npt.Name AS Type,
        npp.Name AS Parent,
		np.Code AS Abbreviation,
		np.Description AS Description,
        c.Name AS Country,
		u.GUID AS UserID,
		IsUserFavourite(u.guid, np.GUID) AS Star
	FROM NamedPlaces np
	CROSS JOIN Users u
	LEFT JOIN NamedPlaceTypes npt ON np.NamedPlaceTypeID = npt.GUID
    LEFT JOIN NamedPlaces npp ON np.ParentID = npp.GUID
    LEFT JOIN Countries c ON np.CountryID = c.GUID;
-- SELECT * FROM NamedEventDetails WHERE Name LIKE '2004%' LIMIT 1;


DELIMITER ;
DROP VIEW IF EXISTS NamedEventDetails;
CREATE VIEW NamedEventDetails
AS
	SELECT
		'Named Event' AS EntityType,
		ne.GUID AS GUID,
		net.Name AS Type,
		ne.Name AS Name,
		ne.Code AS Code,
		ne.Description,
		ne.DateDescription AS Date,
		u.GUID AS UserID,
		IsUserFavourite(u.guid, ne.GUID) AS Star
	FROM NamedEvents ne
	CROSS JOIN Users u
	LEFT JOIN NamedEventTypes net ON ne.NamedEventTypeID = net.GUID;
-- SELECT * FROM NamedEventDetails WHERE Name LIKE '2004%' LIMIT 1;


DELIMITER ;
DROP VIEW IF EXISTS ItemTypeDetails;
CREATE VIEW ItemTypeDetails
AS 
	SELECT
		'Item Type' AS EntityType,
        it.Name AS Name,
		it.GUID AS GUID,
		itp.Name AS Parent,
        it.ScopingNote AS `Scoping Notes`,
		u.GUID AS UserID,
        IsUserFavourite(u.guid, it.GUID) AS Star
   FROM ItemTypes it 
   CROSS JOIN Users u
   LEFT JOIN ItemTypes itp ON it.ParentID = itp.GUID;
-- SELECT * FROM ItemTypeDetails;


DELIMITER ;
DROP VIEW IF EXISTS SubjectDetails;
CREATE VIEW SubjectDetails
AS 
	SELECT
		'Subject' AS EntityType,
        s.Name As Name,
		s.GUID as guid,
        sp.Name AS Parent,
        s.Description AS Description,
		u.GUID AS UserID,
        IsUserFavourite(u.guid, s.GUID) AS Star 
   FROM Subjects s
   CROSS JOIN Users u
   LEFT JOIN Subjects sp ON s.ParentID = sp.GUID;
-- SELECT * FROM SubjectDetails;


DELIMITER ;
DROP VIEW IF EXISTS PerOrgDetails;
CREATE VIEW PerOrgDetails
AS 
	SELECT
		'Person/Organisation' AS EntityType,
        po.Name AS Name,
		po.GUID AS GUID,
		po.FirstName,
        po.LastName,
        po.Title,
        po.Gender,
        pot.Name AS Type,
		u.GUID AS UserID,
        IsUserFavourite(u.guid, po.GUID) AS Star
    FROM PerOrgs po
    CROSS JOIN Users u
    LEFT JOIN PerOrgTypes pot ON po.PerOrgTypeID = pot.GUID;
 -- SELECT * FROM PerOrgDetails;


DELIMITER ;
DROP VIEW IF EXISTS CurriculumElementDetails;
CREATE VIEW CurriculumElementDetails
AS 
	SELECT
		'Curriculum Element' AS EntityType,
        ce.Name AS Name,
		ce.GUID AS guid,
        ce.Code AS Code,
        IFNULL(ce.Content,' ') AS Content,
        c.Name AS Curriculum,
        cs.Name AS Subject,
        cl.Name AS Level,
        cet.Name AS Type,
		u.GUID AS UserID,
        IsUserFavourite(u.guid, ce.GUID) AS Star
    FROM CurriculumElements ce
    CROSS JOIN Users u
    LEFT JOIN Curricula c ON ce.CurriculumID = c.GUID
    LEFT JOIN CurriculumSubjects cs on ce.CurriculumSubjectID = cs.GUID
    LEFT JOIN CurriculumLevels cl ON ce.CurriculumLevelID = cl.GUID
    LEFT JOIN CurriculumElementTypes cet ON ce.CurriculumElementTypeID = cet.GUID;
-- SELECT * FROM CurriculumElementDetails;        


/*
SELECT * FROM CurriculumElementDetails WHERE GUID = 'E8D6EFA4-567C-45E7-B95E-B2CC5F23203F';

UPDATE CurriculumElements
SET Content = '
*Developmental process*:

* Explore different approaches to generating ideas in response to a motivational task (collecting of reference materials, sketching, writing and researching a wide variety of artists and their work that will inform the learner’s own work).
* Engage with own experience of the world through the exploration of signs and symbols drawn from the broader visual culture (collecting interesting, stimulating references and/or objects of personal significance which may prove useful for

*Realisation of a concept*
* Explore and resolve given and specific visual and conceptual challenges such as compositional problems and choice of subject matter.
* Demonstrate the importance of process in relation to the development and realisation of concepts.
'
WHERE Code = 'VA4110'
*/
