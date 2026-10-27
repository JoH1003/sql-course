/*
COVID Cases Analysis
This uses Window functions to calculate cumulative totals and moving avarages, and to rank within groups

This uses a public dataset from https://coronavirus.data.gov.uk/details/cases.
This has the number of cases reported each day for each of the four countries of the UK
I have renamed some column names from the original dataset to make them more clear.
*/
-- Let's take a quick look at a few rows in the table
SELECT   TOP 20 *
FROM     CovidCase AS cc
ORDER BY cc.DateRecorded DESC;

/*
Calculate the cumulative number of cases by each country (on or before March 15th 2020)
Create a resultset with four columns: Country, DateRecorded, DailyCases and CumulativeCases
and with a row for every date and country
*/
SELECT   cc.Country,
         cc.DateRecorded,
         cc.DailyCases,
         SUM(cc.DailyCases) OVER (PARTITION BY cc.Country ORDER BY cc.DateRecorded) AS CumulativeCases
FROM     CovidCase AS cc
WHERE    cc.DateRecorded <= '2020-03-15' -- keep # rows returned manageable to avoid scrolling much
ORDER BY cc.Country, cc.DateRecorded;

/*
To work on the UK as a whole (not by country) 
we must first group by date (to aggregate over the 4 countries) to get the UK total daily cases
Since we have several queries at UK  level, we will use a temp table to do this once: e.g. #uk_cases. Use 'DROP TABLE IF EXISTS'
to remove a duplicate table. DROP means delete. # means temporary that will be overwritten or dropped.
*/
DROP TABLE IF EXISTS #uk_cases;

SELECT   cc.DateRecorded,
         SUM(cc.DailyCases) AS DailyCases
INTO     #uk_cases
FROM     CovidCase AS cc
GROUP BY cc.DateRecorded
ORDER BY cc.DateRecorded;

SELECT *
FROM   #uk_cases;

/*
Calculate the cumulative number of cases in the UK as a whole
Create a resultset with three columns: DateRecorded, DailyCases and CumulativeCases
Note: we must first group by date (to aggregate over the 4 countries) to get the UK total daily cases
*/
SELECT   uk.DateRecorded,
         uk.DailyCases,
         SUM(uk.DailyCases) OVER (ORDER BY uk.DateRecorded) AS CumulativeCases
FROM     #uk_cases AS uk
ORDER BY uk.DateRecorded;

/*
Find the three days with the highest number of cases in the UK- RANK
Create a resultset with three columns: DateRecorded, DailyCases and Ranking, and with three rows
*/
SELECT   TOP 3 uk.DateRecorded,
               uk.DailyCases,
               RANK() OVER (ORDER BY uk.DailyCases DESC) AS Ranking
FROM     #uk_cases AS uk
ORDER BY RANKING; --this ensures the 3 highest numbers and not just any 3 rows.

/*
Find the three days with the highest number of cases in each country 
Create a resultset with 
* four columns: Country, DateRecorded, DailyCases and Ranking 
* 12 rows (4 rows for each country with Ranking of 1,2,and 3
*/
WITH   cte
AS     (SELECT cc.Country,
               cc.DateRecorded,
               cc.DailyCases
        FROM   CovidCase AS cc)
SELECT *
FROM   cte;

----------------
WITH   cte
AS     (SELECT cc.Country,
               cc.DateRecorded,
               cc.DailyCases,
               RANK() OVER (PARTITION BY cc.country ORDER BY cc.DailyCases DESC) AS Ranking
        FROM   CovidCase AS cc)
SELECT *
FROM   cte
WHERE  Ranking <= 3;

/*try again using AI
Find the three days with the highest number of cases in each country 
Create a resultset with 
* four columns: Country, DateRecorded, DailyCases and Ranking 
* 12 rows (4 rows for each country with Ranking of 1,2,and 3
*/
-- using AI   
WITH   cte
AS     (SELECT cc.Country,
               cc.DateRecorded,
               cc.DailyCases,
               RANK() OVER (PARTITION BY cc.Country ORDER BY cc.DailyCases DESC) AS Ranking
        FROM   CovidCase AS cc)
SELECT Country,
       DateRecorded,
       DailyCases,
       Ranking
FROM   cte
WHERE  Ranking <= 3;

/*
Advanced Section
*/
/*
Find the three days with the highest number of cases in each country (using a CROSS APPLY approach).
Create exactly the same resultset as the previous approach.
*/
SELECT   DISTINCT cc.Country,
                  m.DateRecorded,
                  m.DailyCases,
                  m.Ranking
FROM     CovidCase AS cc
         CROSS APPLY (SELECT   TOP 3 z.Country,
                                     z.DateRecorded,
                                     z.DailyCases,
                                     RANK() OVER (PARTITION BY z.country ORDER BY z.DailyCases DESC) AS Ranking
                      FROM     CovidCase AS z
                      WHERE    z.Country = cc.Country
                      ORDER BY z.DailyCases DESC) AS m
ORDER BY cc.Country, m.DailyCases DESC;

/*
Advanced example: Calculate the seven day moving average of cases by country
*/
SELECT   cc.DateRecorded,
         cc.Country,
         cc.DailyCases,
         AVG(cc.DailyCases) OVER (PARTITION BY cc.Country ORDER BY cc.DateRecorded ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS SevenDayMovingAverageCases
FROM     CovidCase AS cc
ORDER BY cc.Country, cc.DateRecorded;