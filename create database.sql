CREATE DATABASE IF NOT EXISTS `COVID`;USE `COVID`;
CREATE TABLE `countries` (
	`ID` INT(11) NOT NULL AUTO_INCREMENT,
	`name` VARCHAR(50) NULL DEFAULT '0' COLLATE 'latin1_swedish_ci',
	`slug` VARCHAR(50) NULL DEFAULT '0' COLLATE 'latin1_swedish_ci',
	`code` VARCHAR(5) NULL DEFAULT NULL COLLATE 'latin1_swedish_ci',
	`lat` FLOAT(12) NULL DEFAULT NULL,
	`lon` FLOAT(12) NULL DEFAULT NULL,
	PRIMARY KEY (`ID`) USING BTREE,
	UNIQUE INDEX `ID` (`ID`) USING BTREE
)
COLLATE='latin1_swedish_ci'
ENGINE=InnoDB
;
CREATE TABLE `cumulative` (
	`ID` INT(11) NOT NULL AUTO_INCREMENT,
	`country` VARCHAR(50) NULL DEFAULT '0' COLLATE 'latin1_swedish_ci',
	`confirmed` INT(11) NULL DEFAULT NULL,
	`deaths` INT(11) NULL DEFAULT NULL,
	`date` DATETIME NULL DEFAULT NULL,
	PRIMARY KEY (`ID`) USING BTREE,
	UNIQUE INDEX `ID` (`ID`) USING BTREE
)
COLLATE='latin1_swedish_ci'
ENGINE=InnoDB
;

CREATE TABLE `daily` (
	`ID` INT(11) NOT NULL AUTO_INCREMENT,
	`country` VARCHAR(50) NULL DEFAULT '0' COLLATE 'latin1_swedish_ci',
	`confirmed` INT(11) NULL DEFAULT NULL,
	`deaths` INT(11) NULL DEFAULT NULL,
	`confirmed7dave` FLOAT(12) NULL DEFAULT NULL,
	`deaths7dave` FLOAT(12) NULL DEFAULT NULL,
	`date` DATETIME NULL DEFAULT NULL,
	PRIMARY KEY (`ID`) USING BTREE,
	UNIQUE INDEX `ID` (`ID`) USING BTREE
)
COLLATE='latin1_swedish_ci'
ENGINE=InnoDB
;


#SELECT * FROM countries
#INSERT INTO countries (name,slug,CODE) VALUES ('Solomon Islands','solomon-islands','SB')
#-TRUNCATE TABLE countries

#SELECT * FROM cumulative
#INSERT INTO cumulative (country,confirmed,deaths,date) VALUES ('country',1,2,'date')
#-TRUNCATE TABLE cumulative
SELECT id,country,confirmed,deaths,date FROM cumulative ORDER BY date desc LIMIT 20

#drop procedure getrecent
DELIMITER //
CREATE PROCEDURE getrecent()
BEGIN
SELECT t1.country, c.code AS iso, t1.confirmed AS latestconfirmed, t2.confirmed AS yesterdayconfirmed
, t1.deaths AS latestdeaths, t2.deaths AS yesterdaydeaths,t1.latestdate,t2.secondlatestdate
FROM
	(
	SELECT c.country,confirmed,deaths,latestdate
	FROM cumulative c
	INNER JOIN
		(SELECT country, MAX(DATE) as latestdate FROM cumulative GROUP BY country) latest
	ON c.country = latest.country AND c.date = latest.latestdate
	) AS t1
INNER JOIN
	(
	SELECT c.country,confirmed,deaths,secondlatestdate
	FROM cumulative c
	INNER JOIN
		(SELECT country, MAX(DATE) as secondlatestdate FROM cumulative WHERE DATE< (SELECT MAX(DATE) FROM cumulative AS tmp WHERE country=tmp.country) GROUP BY country) latest
	ON c.country = latest.country AND c.date = latest.secondlatestdate
	) AS t2
ON t1.country = t2.country
INNER JOIN countries c
ON c.name=t1.country
ORDER BY 1;
END //
DELIMITER ;

call getrecent;


-DROP PROCEDURE getdailyforcountry
DELIMITER //
CREATE PROCEDURE getdailyforcountry(IN countrycode VARCHAR(5))
BEGIN
SELECT country,code,confirmed,deaths,confirmed7dave,deaths7dave,date
FROM daily cm
INNER JOIN countries ct
ON ct.name=cm.country
WHERE ct.code=countrycode
ORDER BY DATE ASC;
END //
DELIMITER ;

CALL getdailyforcountry('GB');


SELECT country,confirmed,deaths,DATE FROM cumulative cm WHERE cm.country='South Africa' ORDER BY cm.country,cm.date ASC

INSERT INTO daily (country,confirmed,deaths,date) VALUES ('South Africa',1674,22,'2020-06-01 00:00:00')
SELECT * FROM daily
-TRUNCATE TABLE daily










































