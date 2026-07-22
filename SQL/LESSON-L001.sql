/*
** ONE-MUSEUM LESSON LOADER
**
** This is a low-level process for the updating of all of the information needed for a lesson
** as will be called from the OneMuseumIngestor when getting a Lesson to load
*/

/*
USE OneMuseum;

SELECT GUID INTO @MuseumGUID FROM Museums WHERE Name = 'Durban Art Gallery';

SELECT CONCAT('MUSEUM = ', @MuseumGUID);

SELECT GUID INTO @SubjectGUID FROM curriculumsubjects WHERE Name = 'Visual Arts';
SELECT CONCAT('SUBJECT = ', @SubjectGUID);

SELECT GUID INTO @ElementGUID FROM curriculumelements WHERE Code = 'VA491';
SELECT CONCAT('ELEMENT = ', @ElementGUID);



SET @Code = '';
SET @Name = 'Allina Ndebele - Umbongo c1980s';

SET @Description = '';

SET @Content = '# Allina Ndebele - Umbongo c1980s  

| | |
|-----|------|
|Museum|Durban Art Gallery|
|Material|Mohair|
|Size|160 x 235 cm|
|Museum Item Number|DAG 2837|
| | |


![Umbongo](/i/A22B708B-E8D7-0CA0-2ACE-5D52B3F3F615 "Umbongo, Allina Ndebele")

Ndebele originally nursed at the Ceza Hospital in Northern KwaZulu-Natal where she met the Swedish couple who were later to start the Evangelical Lutheran Church (ELC) Art and Craft Centre at Rorke’s Drift. She helped them with their Art Occupational Therapy programme where she taught simple weaving. Ndebele later studied in Sweden to become a weaving teacher.

She then left the Rorke’s Drift Centre to work at her father’s kraal in her own workshop. This resulted in this tapestry which recaptured the memories of her childhood and wedding and also the stories her grandmother used to tell.

Ndebele worked intuitively and said “When I work I see the picture and my hand will go over the wool and I know where I will have the image.”

**Umbongo** tells the story of the party that was arranged as a pre-wedding celebration. Ndebele says that “The young lover instructs his friends to rehearse songs which will be sung at the forest party.” (Interview with Burman) 

All the figures at the party face the viewer with the river at the bottom and the trees of the forest at the top. The composition is symmetrical with a large beer pot in the middle which seems to say “So there our Zulu story stands, solid as a rock, for everybody to see: Ndebele and her people do not have to wander anymore”. (Ndebele in Burman)

The figures are all the same size in one frozen moment in time. There is no change in scale according to importance and we cannot even tell who the bride and groom are in the group. The colours of the people differ as Ndebele considered this to be more visuallyinteresting as the colours set up a rhythm across the surface.

Technically, the tapestry is tightly woven from solid mohair wool and is nearly a centimetre thick.

Art, craft and spiritual works mainly from rural South Africa The voice of emerging artists Rorke’s Drift, Polly Street, Nyanga Centres.

## References

- Thorpe, J. It’s never too early - African Art & Craft in KwaZulu-Natal 1960-1990. Indicator Press, Durban. 1994
- Burmann, P. The Thread of the Story: Two South African Women Artists Talk about Their Work: in https://www. jstor.org/stable/pdf/3821084.pdf 2000 (accessed 3 July 2019)
';


INSERT INTO Lessons (MuseumID, LessonTypeID, LessonType, CurriculumSubjectID, CurriculumElementID,
	Code, Name, Keywords)
VALUES (@MuseumGUID, @LessonTypeID, @LessonType, @SubjectGUID, @ElementD,
	@Code, @Name, @Keywords);
    
SET @ID = LAST_INSERT_ID();
SELECT GUID INTO @GUID
FROM Lessons
WHERE ID = @ID;

UPDATE Lessons
SET Description = @Description,
	Content = @Content
WHERE GUID = @GUID;

SELECT GUID INTO @ELementID
FROM CUrriculumElements
WHERE Code = 'VA491';

UPDATE Lessons
SET CurriculumElementID = @ELementID
WHERE GUID = 'DDDAAFC0-E4CE-5015-76AE-8EF17269A9D8';

UPDATE Lessons
SET Description = 'Umbongo tells the story of the party that was arranged as a pre-wedding celebration.'
WHERE GUID = 'DDDAAFC0-E4CE-5015-76AE-8EF17269A9D8';

INSERT INTO PerOrgs(PerOrgTypeID, IsPerson, Name, FullName, KnownAs, FirstName, LastName)
VALUES ('5949ACC5-0762-4D3C-8222-4EA219B807B9', 1, 'Allina Ndebele', 'Allina Ndebele', 'artist', 'Allina', 'Ndebele');

SELECT @IDP = last_insert_id();
SELECT GUID INTO @GUIDP 
FROM PerOrgs WHERE ID = @IDP;

INSERT INTO Categorizations (RefETID, RefGUID, CategoryEtID, CategoryValueID, CategoryValue)
VALUES (565, 'DDDAAFC0-E4CE-5015-76AE-8EF17269A9D8' , 125, '7229963C-7DEE-FFFF-FE94-8C6CAD256CDC', 'Allina Ndebele');

INSERT INTO Categorizations (RefETID, RefGUID, CategoryEtID, CategoryValueID)
VALUES (565, 'DDDAAFC0-E4CE-5015-76AE-8EF17269A9D8' , 155, '8CCDEFA9-F107-49EE-81E4-C1A15D948316');

INSERT INTO Categorizations (RefETID, RefGUID, CategoryETID, CategoryValue)
VALUES (565, 'DDDAAFC0-E4CE-5015-76AE-8EF17269A9D8' , 145, 'wedding');

*/

UPDATE Lessons
SET Content = '# Allina Ndebele - Umbongo c1980s

| | |
|-----|------|
|Museum|Durban Art Gallery|
|Material|Mohair|
|Size|160 x 235 cm|
|Museum Item Number|DAG 2837|

![Umbongo](/i/A22B708B-E8D7-0CA0-2ACE-5D52B3F3F615 "Umbongo, Allina Ndebele")

Ndebele originally nursed at the Ceza Hospital in Northern KwaZulu-Natal where she met the Swedish couple who were later to start the Evangelical Lutheran Church (ELC) Art and Craft Centre at Rorke’s Drift. She helped them with their Art Occupational Therapy programme where she taught simple weaving. Ndebele later studied in Sweden to become a weaving teacher.

She then left the Rorke’s Drift Centre to work at her father’s kraal in her own workshop. This resulted in this tapestry which recaptured the memories of her childhood and wedding and also the stories her grandmother used to tell.

Ndebele worked intuitively and said “When I work I see the picture and my hand will go over the wool and I know where I will have the image.”

**Umbongo** tells the story of the party that was arranged as a pre-wedding celebration. Ndebele says that “The young lover instructs his friends to rehearse songs which will be sung at the forest party.” (Interview with Burman) 

All the figures at the party face the viewer with the river at the bottom and the trees of the forest at the top. The composition is symmetrical with a large beer pot in the middle which seems to say “So there our Zulu story stands, solid as a rock, for everybody to see: Ndebele and her people do not have to wander anymore”. (Ndebele in Burman)

The figures are all the same size in one frozen moment in time. There is no change in scale according to importance and we cannot even tell who the bride and groom are in the group. The colours of the people differ as Ndebele considered this to be more visuallyinteresting as the colours set up a rhythm across the surface.

Technically, the tapestry is tightly woven from solid mohair wool and is nearly a centimetre thick.

Art, craft and spiritual works mainly from rural South Africa The voice of emerging artists Rorke’s Drift, Polly Street, Nyanga Centres.

## References

- Thorpe, J. It’s never too early - African Art & Craft in KwaZulu-Natal 1960-1990. Indicator Press, Durban. 1994
- Burmann, P. The Thread of the Story: Two South African Women Artists Talk about Their Work: in https://www. jstor.org/stable/pdf/3821084.pdf 2000 (accessed 3 July 2019)
'
WHERE GUID = 'DDDAAFC0-E4CE-5015-76AE-8EF17269A9D8'
