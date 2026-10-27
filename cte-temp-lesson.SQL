/*
CTE Subquery TempTable Comparison 

Calculate the total price of all properties sold in each financial year,which starts on 1st April.
We implement this in three ways using 
- a temporary table
- a common table expression (CTE) and the WITH statement
- a simple (self-contained) subquery

*/
-- We use a CASE statement to create a FinancialYear column
SELECT TOP 100 pp.TransactionID,
               pp.TransactionDate,
               pp.Price,
               DATEPART(YEAR, pp.TransactionDate) AS CalendarYear,
               -- CTRL i - asked for AI explanation in plain english: 
               --"Financial years start in April: April–December use this year and next year;
               -- January–March use last year and this year".
               CASE WHEN DATEPART(MONTH, PP.TransactionDate) >= 4 THEN CONCAT('FY ', DATEPART(YEAR, pp.TransactionDate), '-', DATEPART(YEAR, pp.TransactionDate) + 1) ELSE CONCAT('FY ', DATEPART(YEAR, pp.TransactionDate) - 1, '-', DATEPART(YEAR, pp.TransactionDate)) END AS FinancialYear
FROM   PricePaidSW12 AS pp;

/*
Use a temporary table
Microsoft T-SQL only
*/
DROP TABLE IF EXISTS #sale;

SELECT pp.TransactionID,
       pp.TransactionDate,
       pp.Price,
       DATEPART(YEAR, pp.TransactionDate) AS CalendarYear,
       CASE WHEN DATEPART(MONTH, PP.TransactionDate) >= 4 THEN CONCAT('FY ', DATEPART(YEAR, pp.TransactionDate), '-', DATEPART(YEAR, pp.TransactionDate) + 1) ELSE CONCAT('FY ', DATEPART(YEAR, pp.TransactionDate) - 1, '-', DATEPART(YEAR, pp.TransactionDate)) END AS FinancialYear
INTO   #sale
FROM   PricePaidSW12 AS pp;

SELECT TOP 25 *
FROM   #sale;

SELECT   #sale.FinancialYear,
         SUM(#sale.Price) / 1000000.0 AS TotalPriceInMillions
FROM     #sale
GROUP BY #sale.FinancialYear
ORDER BY #sale.FinancialYear;

/*
Use a common table expression CTE and the WITH statement
*/
WITH     sale
AS       (SELECT pp.TransactionID,
                 pp.TransactionDate,
                 pp.Price,
                 DATEPART(YEAR, pp.TransactionDate) AS CalendarYear,
                 CASE WHEN DATEPART(MONTH, PP.TransactionDate) >= 4 THEN CONCAT('FY ', DATEPART(YEAR, pp.TransactionDate), '-', DATEPART(YEAR, pp.TransactionDate) + 1) ELSE CONCAT('FY ', DATEPART(YEAR, pp.TransactionDate) - 1, '-', DATEPART(YEAR, pp.TransactionDate)) END AS FinancialYear
          FROM   PricePaidSW12 AS pp)
SELECT   sale.FinancialYear,
         SUM(sale.Price) / 1000000.0 AS TotalPriceInMillions
FROM     sale
GROUP BY sale.FinancialYear
ORDER BY sale.FinancialYear;

/*
Use a simple subquery
*/
SELECT   sale.FinancialYear,
         SUM(sale.Price) / 1000000.0 AS TotalPriceInMillions
FROM     (SELECT pp.TransactionID,
                 pp.TransactionDate,
                 pp.Price,
                 DATEPART(YEAR, pp.TransactionDate) AS CalendarYear,
                 CASE WHEN DATEPART(MONTH, PP.TransactionDate) >= 4 THEN CONCAT('FY ', DATEPART(YEAR, pp.TransactionDate), '-', DATEPART(YEAR, pp.TransactionDate) + 1) ELSE CONCAT('FY ', DATEPART(YEAR, pp.TransactionDate) - 1, '-', DATEPART(YEAR, pp.TransactionDate)) END AS FinancialYear
          FROM   PricePaidSW12 AS pp) AS sale
GROUP BY sale.FinancialYear
ORDER BY sale.FinancialYear;


-- END