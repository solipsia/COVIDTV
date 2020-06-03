

#SELECT * FROM countries
#INSERT INTO countries (name,slug,CODE) VALUES ('Solomon Islands','solomon-islands','SB')
#-TRUNCATE TABLE countries

#SELECT * FROM cumulative
#INSERT INTO cumulative (country,confirmed,deaths,date) VALUES ('country',1,2,'date')
#-TRUNCATE TABLE cumulative
SELECT id,country,confirmed,deaths,date FROM cumulative ORDER BY date desc LIMIT 20


call getrecent;




CALL getdailyforcountry('AL');


SELECT country,confirmed,deaths,DATE FROM cumulative cm WHERE cm.country='South Africa' ORDER BY cm.country,cm.date ASC

--INSERT INTO daily (country,confirmed,deaths,date) VALUES ('South Africa',1674,22,'2020-06-01 00:00:00')
SELECT * FROM daily
--TRUNCATE TABLE daily

SELECT * FROM countries WHERE NAME LIKE '%kore%'









































