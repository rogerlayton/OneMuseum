use etherbasezamuma22;

DELIMITER $$

DROP PROCEDURE IF EXISTS _SortCodeGenerate
$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `_SortCodeGenerate`(
	IN aItemNumber varchar(255),
    OUT aSortCode varchar(255))
BEGIN

	DECLARE tCount int;
	DECLARE tState int;
	DECLARE CH nchar(1);
	DECLARE I int;
	DECLARE tCHType int;
	DECLARE S varchar(100);
    
	DECLARE tElem varchar(255);
	DECLARE tType char(1);

    DECLARE finished int;

    DECLARE CU_Elem CURSOR FOR
		SELECT `type`, `elem` FROM _Elements ORDER BY id;
      
	DECLARE CONTINUE HANDLER 
        FOR NOT FOUND SET finished = 1;

    DROP TEMPORARY TABLE IF EXISTS _Elements;
    CREATE TEMPORARY TABLE _Elements (id SERIAL,
		`type` char(1), `elem` varchar(200));
        
	SET tState = 0;
	SET tCHType = 0;
	SET tCount = LENGTH(aItemNumber);
	SET S = '';

	-- 2 : cycle through all characters in the string

	SET I = 0;
	WHILE I <= tCount DO
		SET I = I + 1;

		SET CH = SUBSTRING(aItemNumber, I, 1);
		IF CH >= '0' AND CH <= '9' THEN
			SET tCHType = 1;
		ELSEIF CH = ' ' THEN
			SET tCHType = 2;
		ELSE
			SET tCHType = 3;
		END IF;
        
        IF tState = 0 THEN
			IF tCHType = 1 THEN
				SET S = CONCAT(S, CH);
				SET tState = 1;
			ELSEIF tCHType = 2 THEN
				SET tState = 2;
			ELSEIF tCHType = 3 THEN
				SET S = CONCAT(S, CH);
				SET tState = 2;
			END IF;

		ELSEIF tState = 1 THEN
			IF tCHType = 1 THEN
				SET S = CONCAT(S, CH);
			ELSEIF tCHType = 2 THEN
				IF S <> '' THEN
					INSERT INTO _Elements (`type`, `elem`) VALUES ('N', S);
					SET S = '';
					SET tState = 2;
				END IF;
			ELSEIF tCHType = 3 THEN
				IF S <> '' THEN
					INSERT INTO _Elements (`type`, `elem`) VALUES ('N', S);
				END IF;
				SET S = CH;
				SET tState = 2;
			END IF;			

		ELSEIF tState = 2 THEN
			IF tCHType = 1 THEN
				IF S <> '' THEN
					INSERT INTO _Elements (`type`, `elem`) VALUES ('S', S);
				END IF;
				SET S = CH;
				SET tState = 1;
			ELSEIF tCHType = 3 THEN
				SET S = CONCAT(S, CH);
			END IF;
		END IF;

	END WHILE;
    IF S <> '' THEN
		INSERT INTO _Elements (`type`, `elem`) VALUES ('S', S);
	END IF;
	
	SET aSortCode = '';
    SET finished = 0;
    
	OPEN CU_Elem;
getElem: LOOP
	FETCH CU_Elem INTO tType, tElem;
	IF finished = 1 THEN 
		LEAVE getElem;
	END IF;
    IF tType = 'N' THEN
		IF RIGHT(aSortCode, 1) BETWEEN 'A' AND 'Z' THEN
			SET aSortCode = CONCAT(aSortCode, '.');
		END IF;
		SET aSortCode = CONCAT(aSortCode, LPAD(tElem, 6, '000000'));
	ELSE
		IF RIGHT(aSortCode, 1) BETWEEN 'A' AND 'Z' THEN
			SET aSortCode = CONCAT(aSortCode, '.');
		END IF;
		SET aSortCode = CONCAT(aSortCode, tElem);
	END IF;
    
    END LOOP getElem;
    
    CLOSE CU_Elem;
    
    DROP TEMPORARY TABLE IF EXISTS _Elements;

END
$$

DELIMITER ;
SET @SortCode = '';
CALL _SortCodeGenerate('2017.4.45 6-X', @SortCode);
SELECT @SortCode;

DELIMITER $$

DROP PROCEDURE IF EXISTS ItemGenSortCode
$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `ItemGenSortCode`(
	IN aGUID CHAR(36))
BEGIN

	DECLARE tAccessionNumber varchar(255);
    
    SELECT AccessionNumber INTO tAccessionNumber
    FROM Items
    WHERE MeGUID = aGUID;
    
    CALL _SortCodeGenerate(tAccessionNumber, @SortCode);
    
    UPDATE Items
    SET SortCode = @SortCode
    WHERE MeGUID = aGUID;

END
$$


SELECT MeGUID, AccessionNumber, SortCode FROM Items
WHERE MeGUID IN ('0009BEDB-A59F-4BD6-9225-03FD32ABE5DB', '03BBD346-F81F-488D-9E3B-E05527A619C5');

CALL ItemGenSortCode('0009BEDB-A59F-4BD6-9225-03FD32ABE5DB');

CALL ItemGenSortCode('03BBD346-F81F-488D-9E3B-E05527A619C5');

DELIMITER $$

DROP PROCEDURE IF EXISTS ItemGenSortCodeAll
$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `ItemGenSortCodeAll`()
BEGIN

	DECLARE finished int;
    DECLARE tGUID CHAR(36);
    
	DECLARE CU_Items CURSOR FOR
		SELECT MeGUID FROM Items;
        
	OPEN CU_Items;
    
    SET finished = 0;
    
getItem: LOOP
	FETCH CU_Items INTO tGUID;
	IF finished = 1 THEN 
		LEAVE getItem;
	END IF;
    CALL ItemGenSortCode(tGUID);
    END LOOP getItem;

    CLOSE CU_Items;
    
END
$$

/*
SET @E = '123';
SELECT LPAD(@E, 6, '000000');

SET @C = '4ANV';
IF RIGHT(@C, 1) BETWEEN 'A' AND 'Z' THEN
	SELECT 
    
SET @T = '';
SELECT RIGHT(@T, 1);

SELECT * FROM Items;

SELECT MeGUID, AccessionNumber, SortCode, Name, Title
FROM Items;
*/

CALL ItemGenSortCodeAll();



SELECT MeGUID, TopCollectionID FROM Collections;


SELECT ROW_NUMBER() OVER (ORDER BY i.ItemNumber) AS RowNum,  i.MeGUID, i.ItemNumber, i.SortCode, i.Name, 
IFNULL(i.AccessionNumber, i.ItemNumber) AS RefNumber, 
CASE   WHEN LENGTH(i.Name) > 255 THEN SUBSTRING(i.Name, 1, 250) + ' ...'   ELSE i.Name END AS Title2,  1 AS \"Rank\",
CASE   WHEN it.Name IS NOT NULL THEN it.Name   ELSE i.ItemType END AS ItemType,  i.AccessionNumber, 
CASE   WHEN LENGTH(i.BriefDescription) > 80 THEN SUBSTRING(i.BriefDescription, 1, 77) + '...'   ELSE i.BriefDescription END AS Note2,
i.ParentID,  i2.Name AS Parent,  i.NumItems,  i.CollectionID,  c.TopCollectionID,  c.Name AS Collection,
i.CurrentLocationID, 
CASE   WHEN l2.Name IS NULL THEN i.CurrentLocationCode   ELSE    CONCAT(l2.Name,
IFNULL(CONCAT(' / ', i.CurrentLocationCode), ''))   END AS CurrentLocation
FROM Items AS i
LEFT JOIN ItemTypes it ON i.ItemTypeID = it.MeGUID
LEFT JOIN Collections c ON i.CollectionID = c.MeGUID
LEFT JOIN Items i2 ON i.ParentID = i2.MeGUID
LEFT JOIN Locations l1 ON i.NormalLocationID = l1.MeGUID
LEFT JOIN Locations l2 ON i.CurrentLocationID = l2.MeGUID AND i.CollectionID = 'E76A8E1C-EEF9-48F9-87E7-47E1AB99C001'
ORDER BY i.SortCode
LIMIT 0,20
