-- Chapter 5: Grouping and Windowing
--  Lesson 2: Pivoting and Unpivoting Data

USE TSQL2012;
GO

/*  Pivoting Data  */
-- pg 164
WITH PivotData AS
(
  SELECT
    custid,    -- grouping
    shipperid, -- spreading
    freight    -- aggregation
  FROM Sales.Orders
)
SELECT custid, [1], [2], [3]
FROM PivotData
  PIVOT( SUM(freight) FOR shipperid IN ([1],[2],[3]) ) AS P;
  
-- pg 165
SELECT custid, [1], [2], [3]
FROM Sales.Orders
  PIVOT( SUM(freight) FOR shipperid IN ([1],[2],[3]) ) AS P;

-- http://sqlmag.com/t-sql/pivoting-dynamic-way
DECLARE @SQL AS VARCHAR(MAX)
DECLARE @Columns AS VARCHAR(MAX)

SELECT @Columns = 
  COALESCE(@Columns+',','')+QUOTENAME(shipperid)
FROM
(
  SELECT DISTINCT shipperid
  FROM Sales.Orders
) AS B
ORDER BY B.shipperid


SET @SQL = '
WITH PivotData AS
(
  SELECT
    custid,    -- grouping
    shipperid, -- spreading
    freight    -- aggregation
  FROM Sales.Orders
)
SELECT 
  custid, 
  '+@Columns+'
FROM PivotData
  PIVOT
  ( 
    SUM(freight) 
    FOR shipperid 
    IN ('+@Columns+') 
  ) AS PivotResult
ORDER BY custid';

EXEC(@SQL);

/* Unpivoting Data */
USE TSQL2012;
IF OBJECT_ID('Sales.FreightTotals') IS NOT NULL DROP TABLE Sales.FreightTotals;
GO

DECLARE @SQL AS NVARCHAR(4000);
SET @SQL = 'SELECT ''['' + shipperid + '']'' FROM Sales.Orders; '

WITH PivotData AS
(
  SELECT 
    custid,    -- grouping
    shipperid, -- spreading
    freight    -- aggregation
  FROM Sales.Orders
)
SELECT *
INTO Sales.FreightTotals
FROM PivotData
  PIVOT( SUM(freight) FOR shipperid IN ([1],[2],[3]) ) AS P;
  
SELECT * FROM Sales.FreightTotals;

-- pg 167
SELECT custid, shipperid, freight
FROM Sales.FreightTotals
  UNPIVOT( freight FOR shipperid IN ([1],[2],[3]) ) AS U;
  