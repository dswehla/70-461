USE TSQL2012;

-- pg 46
SELECT empid, country, region, city, 
	country + N',' + region + N',' + city AS location
FROM HR.Employees;

-- pg 47
SELECT empid, country, region, city, 
	country + COALESCE(N',' + region, N'') + N',' + city AS location
FROM HR.Employees;

-- pg 47
SELECT empid, country, region, city, 
	CONCAT(country, N',' + region, N',' + city) AS location
FROM HR.Employees;
-- Msg 195, Level 15, State 10, Line 2
-- 'CONCAT' is not a recognized built-in function name.
/* http://stackoverflow.com/a/14877806
   CONCAT is introduced in SQL Server 2012.
   Possible to use ODBC syntax instead:
   {fn CONCAT(str1,str2)} AS attribute
*/
SELECT empid, country, region, city, 
	{fn CONCAT(country, N',' + region, N',' + city)} AS location
FROM HR.Employees;
-- Msg 174, Level 15, State 1, Line 2
-- The CONCAT function requires 2 argument(s).
/* The location attribute requires 5 components.
   Nested CONCAT functions would probably work,
   but arent worth the effort.
*/

-- pg 47
SELECT SUBSTRING('abcde',1,3);
/* SUBSTRING(value_expression ,start_expression ,length_expression )
   The length_expression value must be 0 or a positive integer.
   If 0, the return value is empty, not NULL.
   If negative, generates a syntax error.
   The start_expression value can be negative, but will not wrap around:
      SELECT x = SUBSTRING('abcde',-1,3);
   will return 'a', not 'dea'.
*/
SELECT LEFT('abcde',3)
SELECT RIGHT('abcde',3)
/* LEFT/RIGHT(value_expression ,length_expression )
   The length_expression value must be 0 or a positive integer.
   If 0, the return value is empty, not NULL.
   If negative, generates a syntax error.
*/

/* Functions must be part of a longer statement.
   If run on their own, they return syntax errors.
   SUBSTRING:
   -- Msg 102, Level 15, State 1, Line 1
   -- Incorrect syntax near 'abcde'.
   LEFT:
   -- Msg 156, Level 15, State 1, Line 1
   -- Incorrect syntax near the keyword 'LEFT'.
   RIGHT:
   -- Msg 156, Level 15, State 1, Line 1
   -- Incorrect syntax near the keyword 'RIGHT'.
*/

/*	String Length	*/
-- pg 48
SELECT CHARINDEX(' ', 'Itzik Ben-Gan'); -- Returns 6
-- Finds first location of a fixed character string.

SELECT PATINDEX('%[0-9]%', 'abcd123efgh'); -- Returns 5
-- Finds first location of a fixed character pattern (REGEX).

SELECT LEN(N'xyz '); -- Returns 3
-- Returns count of characters in string, minus trailing spaces.

SELECT DATALENGTH(N'xyz '); -- Returns 8
-- Returns count of bytes in string. Keeps minus trailing spaces.
-- Unicode characters (N'string') use 2 bytes each.

/*	String Alteration	*/
-- pg 48
SELECT REPLACE('.1.2.3','.','/'); -- Returns /1/2/3
-- In Str1, replace Str2 with Str3

-- pg 49
SELECT REPLICATE('0',10); -- Returns 0000000000
-- Prints StrArg1 IntArg2 number of times.
SELECT STUFF(',x,y,z',1,1,''); -- Returns x,y,z (removes leading comma)
-- In StrArg1, starts at position IntArg2, and deletes IntArg3 number of
-- characters, replacing them with optional StrArg4.

/*	String Formatting	*/
-- pg 49
SELECT UPPER('Lower-To-Upper'); -- Returns 'LOWER-TO-UPPER'
SELECT LOWER('Upper-to-Lower'); -- Returns 'upper-to-lower'
SELECT LTRIM(' spaces '); -- Returns 'spaces '
SELECT RTRIM(' spaces '); -- Returns ' spaces'
SELECT FORMAT(1759,'0000000000'); -- Should return '0000001759'
-- Msg 195, Level 15, State 10, Line 2
-- 'FORMAT' is not a recognized built-in function name.
-- FORMAT was introduced in SQL Server 2012.

/*	CASE Expression and Related Functions*/
-- pg 49 (simple form)
-- Single input value (discontinued) after CASE
-- Tests scalar values (0,1) in WHEN clauses
SELECT productid, productname, unitprice, discontinued, 
  CASE discontinued
    WHEN 0 THEN 'No'
    WHEN 1 THEN 'Yes'
    ELSE 'Unknown'
  END AS discontinued_desc
FROM Production.Products;

-- pg 50 (searched form)
-- No input value after CASE
-- Tests predicates (unitprice OPERATOR VALUE) in WHEN clauses
SELECT productid, productname, unitprice, 
  CASE
    WHEN unitprice < 20.00 THEN 'Low'
    WHEN unitprice < 40.00 THEN 'Medium'
    WHEN unitprice >= 40.00 THEN 'High'
    ELSE 'Unknown'
  END AS discontinued_desc
FROM Production.Products;

-- pg 51 (CASE abbreviations)
SELECT COALESCE(NULL, 'x','y'); -- Returns 'x'
-- Returns first non-NULL result from N-length list of expressions. Standard SQL.
-- Typical use is to replace NULL with empty string or other value.
-- Use when concatenating with plus operator (+) to prevent NULLs from NULLing whole string.
SELECT ISNULL(NULL, 'x'); -- Returns 'x'
-- Returns first non-NULL from exactly two expressions. Non-standard T-SQL.

-- pg 51 (COALESCE and ISNULL handle output type differently)
DECLARE
  @x AS VARCHAR(3) = NULL,
  @y AS VARCHAR(10) = '1234567890';
SELECT COALESCE(@x, @y) AS [COALESCE], ISNULL(@x, @y) AS [ISNULL];
/*
COALESCE	ISNULL
1234567890	123
*/
-- ISNULL: Data type of first arg determines output type; @y value curtailed to meet @x def.
-- COALESCE: Data type of output value determines output type; @y value meets its own def.

-- pg 52 (More CASE abbreviations, for migrating from Access)
-- IIF and CHOOSE were introduced in 2012.
SELECT IIF(2012 = 2012, 1, 0); -- Should return 1
SELECT CHOOSE(2,'x','y','z'); -- Should return 'y'

/*	Practice	*/
-- Exercise 1
SELECT empid, 
	firstname + N' ' + lastname AS fullname, 
	YEAR(birthdate) AS birthyear
FROM HR.Employees;

-- Exercise 2
SELECT EOMONTH(SYSDATETIME()); -- EOMONTH introduced in 2012.
SELECT EOMONTH(DATEFROMPARTS(SYSDATETIME()), 12, 31); -- DATEFROMPARTS new in 2012.

-- Exercise 3
SELECT productid, FORMAT(productid,'0000000000') AS str_productid
FROM Production.Products; -- FORMAT new in 2012

SELECT productid, RIGHT(REPLICATE('0',10) + CAST(productid AS VARCHAR (10)), 10) AS str_productid
FROM Production.Products; -- RIGHT new in 2005

SELECT productid, FORMAT(productid,'d10') AS str_productid
FROM Production.Products; -- For explanation of 'd10', see documentation at
-- https://msdn.microsoft.com/en-us/library/hh213505.aspx
