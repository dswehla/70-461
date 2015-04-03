USE TSQL2012;
GO

/* Ch. 4, Lesson3: Using Set Operators: UNION (ALL), INTERSECT, EXCEPT  */
/*  <query 1>                   -- Provides column names
    <set operator>              -- NULLs considered equal
    <query 2>                   -- Column count and type must match <query 1>
    [ORDER BY <order_by_list>]  -- Optional. Disallowed for queries.
    
    Precedence: () > INTERSECT > UNION=EXCEPT
*/

/*  UNION and UNION ALL*/
-- pg 137
-- UNION query has implied DISTINCT property on each result set
SELECT country, region, city
FROM HR.Employees     -- Returns 9 rows (5 distinct)

UNION                 -- Returns 71 rows (not 74)

SELECT country, region, city
FROM Sales.Customers; -- Returns 91 rows (69 distinct)


-- pg 138
-- UNION ALL returns duplicate rows in both (all) result sets.
-- If it can be known ahead of time that there would be no duplicates in result sets,
-- use UNION ALL, so that DB engine won't waste time trying to remove them.
SELECT country, region, city
FROM HR.Employees     -- Returns 9 rows (5 distinct)

UNION ALL             -- Returns 100 rows (71 distinct)

SELECT country, region, city
FROM Sales.Customers; -- Returns 91 rows (66 distinct)

-- Can we name result sets, &/or use more than two of them?
-- Yes, we can alias result sets.
-- UNION removes duplicates from complete set, not just individual sets; returns 5 rows.
-- UNION ALL leaves all duplicates; returns 27 rows.
SELECT country, region, city
FROM Sales.Customers AS A

UNION

SELECT country, region, city
FROM Sales.Customers AS B

UNION

SELECT country, region, city
FROM Sales.Customers AS C;


/*  INTERSECT */
-- Returns distinct rows common to both sets; finds shared rows first, then unique in that set.
-- pg 139
SELECT country, region, city
FROM HR.Employees

INTERSECT

SELECT country, region, city
FROM Sales.Customers;
-- Returns 3 rows.


/*  EXCEPT  */
-- For each distinct result in query 2, removes all instances in query 1,
-- then returns distinct rows from that set.
-- pg 140
SELECT country, region, city
FROM HR.Employees

EXCEPT

SELECT country, region, city
FROM Sales.Customers;
-- Returns 2 rows


/*  Practice: Using Set Operators */
-- Exercise 1: EXCEPT
-- pg 141
SELECT O.empid
FROM Sales.Orders AS O
WHERE O.custid = 1

EXCEPT

SELECT O.empid
FROM Sales.Orders AS O
WHERE O.custid = 2;
-- No need for aliases


SELECT empid
FROM Sales.Orders
WHERE custid = 1  -- Returns 6 rows

EXCEPT            -- Returns 2 rows

SELECT empid
FROM Sales.Orders
WHERE custid = 2; -- Returns 4 rows

-- Exercise 2: INTERSECT
-- pg 142
SELECT empid
FROM Sales.Orders
WHERE custid = 1  -- Returns 6 rows

INTERSECT         -- Returns 2 rows, but different ones than EXCEPT

SELECT empid
FROM Sales.Orders
WHERE custid = 2; -- Returns 4 rows


/* Lesson Review */
-- pg 142
-- 1: A, C, D
-- 2: D
-- 3: B
