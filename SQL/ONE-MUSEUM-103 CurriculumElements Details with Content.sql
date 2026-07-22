CREATE 
    ALGORITHM = UNDEFINED 
    DEFINER = `root`@`localhost` 
    SQL SECURITY DEFINER
VIEW `onemuseum2`.`curriculumelementdetails` AS
    SELECT 
        'Curriculum Element' AS `EntityType`,
        `ce`.`Name` AS `Name`,
        `ce`.`GUID` AS `guid`,
        `ce`.`Code` AS `Code`,
        IFNULL(`ce`.`Content`, ' ') AS `Content`,
        `c`.`Name` AS `Curriculum`,
        `cs`.`Name` AS `Subject`,
        `cl`.`Name` AS `Level`,
        `cet`.`Name` AS `Type`,
        `u`.`GUID` AS `UserID`,
        ISUSERFAVOURITE(`u`.`GUID`, `ce`.`GUID`) AS `Star`
    FROM
        (((((`onemuseum2`.`curriculumelements` `ce`
        JOIN `onemuseum2`.`users` `u`)
        LEFT JOIN `onemuseum2`.`curricula` `c` ON (`ce`.`CurriculumID` = `c`.`GUID`))
        LEFT JOIN `onemuseum2`.`curriculumsubjects` `cs` ON (`ce`.`CurriculumSubjectID` = `cs`.`GUID`))
        LEFT JOIN `onemuseum2`.`curriculumlevels` `cl` ON (`ce`.`CurriculumLevelID` = `cl`.`GUID`))
        LEFT JOIN `onemuseum2`.`curriculumelementtypes` `cet` ON (`ce`.`CurriculumElementTypeID` = `cet`.`GUID`))