USE TSQL2012;

/*	Lesson 1: Filtering Data with Predicates	*/
-- Predicates, Three-Valued Logic, and Search Arguments (SARGs)
-- pg 63
SELECT empid, firstname, lastname, country, region, city
FROM HR.Employees
WHERE country = N'USA';
-- Returns USA employees, as expected.

SELECT empid, firstname, lastname, country, region, city
FROM HR.Employees
WHERE region = N'WA';
-- Returns WA employees, as expected.

-- pg 64
SELECT empid, firstname, lastname, country, region, city
FROM HR.Employees
WHERE region <> N'WA';
-- Returns empty set, as "not expected".
-- Only values in [region] are WA and NULL, and NULLs are discarded.

SELECT empid, firstname, lastname, country, region, city
FROM HR.Employees
WHERE region <> N'WA'
   OR region IS NULL;
-- Specifically asking for NULL brings in the UK employees.

-- pg 65
DECLARE @dt AS DATETIME = '2006-07-16 00:00:00.000';
SELECT orderid, orderdate, empid
FROM Sales.Orders
WHERE shippeddate = @dt;
-- Dates need to be in single quotes to distinguish from numbers.

DECLARE @dt AS DATETIME = NULL;
SELECT orderid, orderdate, empid
FROM Sales.Orders
WHERE COALESCE(shippeddate, '19000101') = COALESCE(@dt, '19000101');

-- pg 66
DECLARE @dt AS DATETIME = NULL;
SELECT orderid, orderdate, empid
FROM Sales.Orders
WHERE shippeddate = @dt
   OR (shippeddate IS NULL AND @dt IS NULL);

-- Combining Predicates
-- pg 68
DECLARE @str1 AS STR = 'abc';
-- Using CAST to convert a value to an incompatible type will fail.
SELECT CAST(@str1 AS INT);
-- Use TRY_CAST to return NULL instead. TRY_CAST new in SQL Server 2012.
SELECT TRY_CAST(@str1 AS INT);

-- Filtering Character Data
-- pg 68
SELECT empid, firstname, lastname
FROM HR.Employees
WHERE lastname = 'Davis';
-- [lastname] field is Unicode, so should use N'Davis'.
-- Works due to implicit conversion, but takes a sec.
SELECT empid, firstname, lastname
FROM HR.Employees
WHERE lastname = N'Davis';

-- pg 69
SELECT empid, firstname, lastname
FROM HR.Employees
WHERE lastname LIKE N'D%';
-- Use % wildcard to return all lastnames starting with D.

-- Use ESCAPE keyword to define your own escape character.
-- Underscore matches single character in search pattern.
-- To search for literal underscores, escape them:
-- WHERE col1 LIKE '!_%' ESCAPE '!' 

-- Filtering Date and Time Data
-- pg 70
SELECT orderid, orderdate, empid, custid
FROM Sales.Orders
WHERE orderdate = '02/12/07';
-- Returns rows where orderdate = 2007-02-12 00:00:00.000
-- When search date is formatted, DB engine uses login's location setting to determine meaning.
-- Use standardized form instead:
SELECT orderid, orderdate, empid, custid
FROM Sales.Orders
WHERE orderdate = '20070212';
-- yyyymmdd with no dashes is language-neutral.
-- Some date & time datatypes are language-neutral. Others aren't. Pay attention.

-- pg 71
SELECT orderid, orderdate, empid, custid
FROM Sales.Orders
WHERE orderdate >= '20070201' AND orderdate < '20070301';
-- No manipulation of filtered column leaves WHERE clause as a search argument (SARG).
-- Using >= and < is safer than BETWEEN, because BETWEEN includes the right-hand value,
-- and since different datatypes have different precision, the results can be unexpected.
-- WHERE orderdate BETWEEN '20070201' AND '20070228 23:59:59.999' rounds up to 20070301.

-- pg 72
-- Exercise 1
SELECT orderid, orderdate, custid, empid
FROM Sales.Orders
WHERE shippeddate = NULL;
-- NULL = NULL is not a match, so is discarded. Returns empty set.

SELECT orderid, orderdate, custid, empid
FROM Sales.Orders
WHERE shippeddate IS NULL;
-- Returns expected result: rows with NULLs.

-- pg 73
-- Exercise 2
SELECT orderid, orderdate, custid, empid
FROM Sales.Orders
WHERE orderdate BETWEEN '20080211' AND '20080212 23:59:59.999';
-- Second value rounds up due to DATETIME precision, so results include 2008-02-13.

SELECT orderid, orderdate, custid, empid
FROM Sales.Orders
WHERE orderdate >= '20080211' AND orderdate < '20080213';
-- Returns 5 rows instead of 7. None are 2008-02-13.

-- pg 74
-- Lesson Review
-- 1. B
-- 2. A B C
-- 3. B E

/*	Lesson 2: Sorting Data	*/
-- pg 75
SELECT empid, firstname, lastname, city, MONTH(birthdate) AS birthmonth
FROM HR.Employees
WHERE country = N'USA' AND region = N'WA';
-- No guaranteed row order, even if it looks like empid order.
 
-- Using the ORDER BY Clause to Sort Data
-- pg 76
SELECT empid, firstname, lastname, city, MONTH(birthdate) AS birthmonth
FROM HR.Employees
WHERE country = N'USA' AND region = N'WA'
ORDER BY city;
-- Some order imposed, but still not deterministic; same-city result order is arbitrary.

-- pg 77
SELECT empid, firstname, lastname, city, MONTH(birthdate) AS birthmonth
FROM HR.Employees
WHERE country = N'USA' AND region = N'WA'
ORDER BY city DESC;
-- Same as pg 76, just reverse order.

SELECT empid, firstname, lastname, city, MONTH(birthdate) AS birthmonth
FROM HR.Employees
WHERE country = N'USA' AND region = N'WA'
ORDER BY city, empid;
-- Adding a guaranteed-unique column value ensures guaranteed sort order; is deterministic.

-- pg 78
SELECT empid, firstname, lastname, city, MONTH(birthdate) AS birthmonth
FROM HR.Employees
WHERE country = N'USA' AND region = N'WA'
ORDER BY 4, 1;
-- T-SQL allows ordering by column number, where column position matches SELECT order.
-- This is non-standard SQL and not relational, and easy to mess up. Don't do it.

SELECT empid, city, firstname, lastname, MONTH(birthdate) AS birthmonth
FROM HR.Employees
WHERE country = N'USA' AND region = N'WA'
ORDER BY 4, 1;
-- Switch the SELECT order, and forget to update the column values, gives unexpected result.
-- Now ordered by lastname instead of city.

SELECT empid, city
FROM HR.Employees
WHERE country = N'USA' AND region = N'WA'
ORDER BY birthdate;
-- Possible to sort by rows that aren't returned.
-- Can do this in Access by unchecking the 'visible' box in query design GUI.

-- pg 79
SELECT DISTINCT city
FROM HR.Employees
WHERE country = N'USA' AND region = N'WA'
ORDER BY birthdate;
-- Msg 145, Level 15, State 1, Line 2
-- ORDER BY items must appear in the select list if SELECT DISTINCT is specified.
-- Multiple birthdates can be returned for each unique city, and no way to choose between them.

SELECT DISTINCT city
FROM HR.Employees
WHERE country = N'USA' AND region = N'WA'
ORDER BY city;
-- Always safe and sensible to order by selected attributes.

SELECT empid, city, firstname, lastname, MONTH(birthdate) AS birthmonth
FROM HR.Employees
WHERE country = N'USA' AND region = N'WA'
ORDER BY birthmonth;
-- ORDER BY clause is evaluated after SELECT, so aliased column names are available.

-- pg 80
SELECT orderid, shippeddate
FROM Sales.Orders
WHERE custid = 20
ORDER BY shippeddate;
-- SQL standard says NULLs should sort together, but doesn't specify before or after non-NULLs.
-- T-SQL sorts them before.

SELECT orderid, shippeddate
FROM Sales.Orders
WHERE custid = 20
ORDER BY 
	CASE shippeddate
		WHEN NULL THEN SYSDATETIME()
		ELSE shippeddate
	END;
-- Try to sort NULLs after non-NULLs, while shippeddate still sorted ASC.
-- Simple form of CASE didn't work. Tests scalar values, and NULL is not a value.

SELECT orderid, shippeddate
FROM Sales.Orders
WHERE custid = 20
ORDER BY 
	CASE 
		WHEN shippeddate IS NULL THEN SYSDATETIME()
		ELSE shippeddate
	END;
-- Searched form of CASE did work. Predicates in WHEN clauses can test for NULL.

-- pg 81, Exercise 1
SELECT orderid, empid, shipperid, shippeddate
FROM Sales.Orders
WHERE custid = 77;
-- No sorting specified means result is relational and non-deterministic.

-- pg 82, Exercise 1
SELECT orderid, empid, shipperid, shippeddate
FROM Sales.Orders
WHERE custid = 77
ORDER BY shipperid;
-- Some order, so not relational, but duplicate shipperid values, so still not deterministic.

-- pg 82, Exercise 2
SELECT orderid, empid, shipperid, shippeddate
FROM Sales.Orders
WHERE custid = 77
ORDER BY shipperid, shippeddate DESC;
-- For the results given, this order is deterministic, but the combination isn't unique,
-- so later results might not be.

-- pg 83, Exercise 2
SELECT orderid, empid, shipperid, shippeddate
FROM Sales.Orders
WHERE custid = 77
ORDER BY shipperid, shippeddate DESC, orderid DESC;
-- Using a unique value to sort by guarantees deterministic result.

-- pg 83, Lesson Review
-- 1. A
-- 2. C
-- 3. B C D

/*	Lesson 3: Filtering Data with TOP and OFFSET-FETCH	*/
-- pg 85
SELECT TOP (3) orderid, orderdate, custid, empid
FROM Sales.Orders
ORDER BY orderdate DESC;
-- Returns 3 most recent orders.

SELECT TOP (1) PERCENT orderid, orderdate, custid, empid
FROM Sales.Orders
ORDER BY orderdate DESC;
-- Returns 9 rows. 830/100 = 8.3, round up to next whole number.

-- pg 86
DECLARE @n AS BIGINT = 5;
SELECT TOP (@n) orderid, orderdate, custid, empid
FROM Sales.Orders
ORDER BY orderdate DESC;
-- TOP arg can be variable. This query returns 5 rows.

SELECT TOP (3) orderid, orderdate, custid, empid
FROM Sales.Orders;
-- Selecting TOP rows without ordering is possible, even if usually pointless.

SELECT TOP (3) orderid, orderdate, custid, empid
FROM Sales.Orders
ORDER BY (SELECT NULL);
-- You can order by NULL to let others know that, yes, you meant to leave the query unordered.

SELECT TOP (3) orderid, orderdate, custid, empid
FROM Sales.Orders
ORDER BY orderdate DESC;
-- Original query from this lesson is not deterministic, since sorted by non-unique values.

-- pg 87
SELECT TOP (3) WITH TIES orderid, orderdate, custid, empid
FROM Sales.Orders
ORDER BY orderdate DESC;
-- Original query from this lesson is not deterministic, since sorted by non-unique values.
-- Using WITH TIES is one way to resolve two or more identical values in ordered column.
-- This query returns 4 rows, since there are 4 order dates of 2008-05-06.

SELECT TOP (3) WITH TIES orderid, orderdate, custid, empid
FROM Sales.Orders
ORDER BY orderdate DESC, orderid DESC;
-- To prevent returning more rows than desired, use a tie-breaker (unique) order value.

SELECT TOP (3) orderid, orderdate, custid, empid
FROM Sales.Orders
ORDER BY orderdate DESC, orderid DESC;
-- Book includes WITH TIES option in this query. Don't think it's actually necessary.

-- Filtering Data with OFFSET-FETCH
-- pg 88
SELECT orderid, orderdate, custid, empid
FROM Sales.Orders
ORDER BY orderdate DESC, orderid DESC
OFFSET 50 ROWS FETCH NEXT 25 ROWS ONLY;
-- Msg 102, Level 15, State 1, Line 4
-- Incorrect syntax near 'OFFSET'.
-- Msg 153, Level 15, State 2, Line 4
-- Invalid usage of the option NEXT in the FETCH statement.
/*
Meant to return rows 51 to 75 of initial result set.

https://msdn.microsoft.com/en-us/library/ms180152.aspx
https://msdn.microsoft.com/en-us/library/ms180152(v=sql.90).aspx
FETCH supported since 2005, to retrieve a specific row from a cursor.

https://msdn.microsoft.com/en-us/library/ms188385(v=sql.110).aspx
The OFFSET-FETCH option to modify the ORDER BY clause was new in 2012.
*/

SELECT orderid, orderdate, custid, empid
FROM Sales.Orders
ORDER BY orderdate DESC, orderid DESC
OFFSET 0 ROWS FETCH FIRST 25 ROWS ONLY;
-- FIRST and NEXT are equivalent in the FETCH portion, as ROW and ROWS are in the OFFSET.

-- PG 89
SELECT orderid, orderdate, custid, empid
FROM Sales.Orders
ORDER BY orderdate DESC, orderid DESC
OFFSET 50 ROWS;
-- FETCH clause requires OFFSET, but OFFSET doesn't require FETCH.
-- Both require ORDER BY.

SELECT orderid, orderdate, custid, empid
FROM Sales.Orders
ORDER BY (SELECT NULL)
OFFSET 0 ROWS FETCH FIRST 3 ROWS ONLY;
-- As before, you can filter from arbitrary result set, and indicate the intention.

DECLARE @pagesize AS BIGINT = 25, @pagenum AS BIGINT = 3;
SELECT orderid, orderdate, custid, empid
FROM Sales.Orders
ORDER BY orderdate DESC, orderid DESC
OFFSET (@pagenum - 1)*@pagesize ROWS FETCH NEXT @pagesize ROWS ONLY;
-- Arguments can be expressions. Expression above returns a page of requested results.
-- Book has @pagesize where @pagenum should be.

-- pg 91
-- Exercise 1
SELECT TOP (5) productid, unitprice
FROM Production.Products
WHERE categoryid = 1
ORDER BY unitprice DESC;
-- Last two results are tied. There may be more matching rows. Result is not deterministic.

SELECT TOP (5) WITH TIES productid, unitprice
FROM Production.Products
WHERE categoryid = 1
ORDER BY unitprice DESC;
-- Determinism option 1: Include all ties. Returns 7 rows.

-- pg 92, Exercise 1
SELECT TOP (5) productid, unitprice
FROM Production.Products
WHERE categoryid = 1
ORDER BY unitprice DESC, productid DESC;
-- Determinism option 2: Use a tiebreaker to resolve ordering issue.

-- pg 92, Exercise 2
SELECT productid, categoryid, unitprice
FROM Production.Products
ORDER BY unitprice, productid
OFFSET 0 ROWS FETCH FIRST 5 ONLY;
-- Hardcode values for FIRST 5 rows.

SELECT productid, categoryid, unitprice
FROM Production.Products
ORDER BY unitprice, productid
OFFSET 5 ROWS FETCH NEXT 5 ONLY;
-- Hardcode values for NEXT 5 rows.

-- pg 93, Exercise 2
SELECT productid, categoryid, unitprice
FROM Production.Products
ORDER BY unitprice, productid
OFFSET 10 ROWS FETCH NEXT 5 ONLY;
-- Hardcode values for rows 11 to 15.

-- pg 94, Lesson Review
-- 1. B
-- 2. (B wrong) F
-- 3. A C
 