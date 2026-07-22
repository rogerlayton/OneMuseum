/*
ONE-MUSEUM-101

Update the view CategoriesAll to include ClassName
*/

ALTER 
    ALGORITHM = UNDEFINED 
    DEFINER = `root`@`%` 
    SQL SECURITY DEFINER
VIEW `categoriesall` AS
    SELECT 
        `c`.`GUID` AS `GUID`,
        115 AS `RefETID`,
        'namedevent' AS `Class`,
        'Named Event' AS ClassName,
        `c`.`Code` AS `Code`,
        `c`.`Name` AS `Name`
    FROM
        `namedevents` `c` 
    UNION SELECT 
        `c`.`GUID` AS `GUID`,
        107 AS `RefETID`,
        'namedplace' AS `Class`,
        'Named Place' AS ClassName,
        `c`.`Code` AS `Code`,
        `c`.`Name` AS `Name`
    FROM
        `namedplaces` `c` 
    UNION SELECT 
        `c`.`GUID` AS `GUID`,
        125 AS `RefETID`,
        'perorg' AS `Class`,
        'Person/Organisation' AS ClassName,
        '' AS `Code`,
        `c`.`Name` AS `Name`
    FROM
        `perorgs` `c` 
    UNION SELECT 
        `c`.`GUID` AS `GUID`,
        145 AS `RefETID`,
        'subject' AS `Class`,
        'Subject' AS ClassName,
        '' AS `Code`,
        `c`.`Name` AS `Name`
    FROM
        `subjects` `c` 
    UNION SELECT 
        `c`.`GUID` AS `GUID`,
        155 AS `RefETID`,
        'curriculumsubject' AS `Class`,
        'Curriculum Subject' AS ClassName,
        `c`.`Code` AS `Code`,
        `c`.`Name` AS `Name`
    FROM
        `curriculumsubjects` `c` 
    UNION SELECT 
        `c`.`GUID` AS `GUID`,
        155 AS `RefETID`,
        'curriculumelement' AS `Class`,
        'Curriculum Element' AS ClassName,
        `c`.`Code` AS `Code`,
        `c`.`Name` AS `Name`
    FROM
        `curriculumelements` `c` 
    UNION SELECT 
        `c`.`GUID` AS `GUID`,
        531 AS `RefETID`,
        'itemtype' AS `Class`,
        'Item Type' AS ClassName,
        `c`.`Code` AS `Code`,
        `c`.`Name` AS `Name`
    FROM
        `itemtypes` `c`