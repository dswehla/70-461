-- Chapter 5: Grouping and Windowing
--  Lesson 1: Writing Grouped Queries

/*  Working with a Single Grouping Set  */
-- pg 150
USE TSQL2012;

SELECT COUNT(*) AS numorders
FROM Sales.Orders;
-- Returns 830

-- pg 151
SELECT shipperid, COUNT(*) AS numorders
FROM Sales.Orders
GROUP BY shipperid;

-- pg 151
SELECT shipperid, YEAR(shippeddate) as shippedyear, COUNT(*) AS numorders
FROM Sales.Orders
GROUP BY shipperid, YEAR(shippeddate);

-- pg 152
SELECT shipperid, YEAR(shippeddate) as shippedyear, COUNT(*) AS numorders
FROM Sales.Orders
WHERE YEAR(shippeddate) IS NOT NULL
GROUP BY shipperid, YEAR(shippeddate)
HAVING COUNT(*) < 100;

-- pg 152
-- COUNT(*) includes nulls
SELECT shipperid, 
  COUNT(*) AS numorders, 
  COUNT(shippeddate) AS shippedorders, 
  MIN(shippeddate) AS firstshippeddate, 
  MAX(shippeddate) AS lastshippeddate, 
  SUM(val) AS totalvalue
FROM Sales.OrderValues
WHERE YEAR(shippeddate) IS NOT NULL
GROUP BY shipperid;

-- pg 153
SELECT shipperid, COUNT(DISTINCT shippeddate) AS numshippingdates
FROM Sales.Orders
GROUP BY shipperid;

-- pg 153
-- Deliberately bad code. S.companyname needs to be in GROUP BY list.
SELECT S.shipperid, S.companyname, COUNT(*) AS numorders
FROM Sales.Shippers AS S
  JOIN Sales.Orders AS O
    ON S.shipperid = O.shipperid
GROUP BY S.shipperid;

-- Workarounds for columns you don't really need to group by, but have to anyway.
-- pg 154
-- Just group by it already. Makes most sense, works best with query optimizer.
SELECT S.shipperid, S.companyname, COUNT(*) AS numorders
FROM Sales.Shippers AS S
  JOIN Sales.Orders AS O
    ON S.shipperid = O.shipperid
GROUP BY S.shipperid, S.companyname;

-- pg 154
-- Include in aggregate function. Works, but counterintuitive.
SELECT S.shipperid, MAX(S.companyname), COUNT(*) AS numorders
FROM Sales.Shippers AS S
  JOIN Sales.Orders AS O
    ON S.shipperid = O.shipperid
GROUP BY S.shipperid, S.companyname;

-- pg 154
-- Do some funky CTE voodoo. Gets processed essentially same as first, but with more code.
WITH C AS
(
  SELECT shipperid, COUNT(*) AS numorders
  FROM Sales.Orders
  GROUP BY shipperid
)
SELECT S.shipperid, S.companyname, numorders
FROM Sales.Shippers AS S
  INNER JOIN C
    ON S.shipperid = C.shipperid;

/*  Working with Multiple Grouping Sets  */
-- pg 155
SELECT shipperid, YEAR(shippeddate) AS shipyear, COUNT(*) AS numorders
FROM Sales.Orders
GROUP BY GROUPING SETS
(
  (shipperid, YEAR(shippeddate)),
  (shipperid),
  (YEAR(shippeddate)), 
  (/* empty set */)
);
-- Result set has empty set appearing next to last, before shipperid set.
-- The first two set appear to be intermixes. Presumably because no ORDER BY clause.
-- How do you order by grouping sets? Clause 'ORDER BY GROUPING SETS' doesn't work.

-- It's ORDER BY GROUPING() (see pg 161). Kinda works, but not as expected.
-- Need to research further.
-- Error: The GROUPING function requires 1 argument(s).
-- Error: Cannot use an aggregate or a subquery in an expression used for the group by list of a GROUP BY clause.
SELECT shipperid, YEAR(shippeddate) AS shipyear, COUNT(*) AS numorders
FROM Sales.Orders
GROUP BY GROUPING SETS
(
  (shipperid, YEAR(shippeddate)),
  (shipperid),
  (YEAR(shippeddate)), 
  (/* empty set */)
)
ORDER BY 
  --GROUPING(shipperid, YEAR(shippeddate)),
  GROUPING(YEAR(shippeddate)), 
  GROUPING(shipperid)
  --GROUPING(/* empty set */)
;

-- pg 156
-- CUBE does all possible combos of input expressions, including empty set.
SELECT shipperid, YEAR(shippeddate) AS shipyear, COUNT(*) AS numorders
FROM Sales.Orders
GROUP BY CUBE(shipperid, YEAR(shippeddate));

-- pg 157
-- ROLLUP is like CUBE, but for hierarchical info;
-- assumes that input expressions are arranged high-to-low.
-- NULLs used as placeholders, so hard to tell difference between placeholders and NULL values.
SELECT shipcountry, shipregion, shipcity, COUNT(*) AS numorders
FROM Sales.Orders
GROUP BY ROLLUP(shipcountry, shipregion, shipcity);

-- pg 157
-- One solution to 'placeholder vs NULL value' problem is GROUPING function.
-- Returns 0 when input is part of grouping set, and 1 when it's not.
-- You can put value and grouping columns together to make it easier to spot pairs.
-- Look for the stairstep shape.
SELECT 
  shipcountry, GROUPING(shipcountry) AS grpcountry,
  shipregion,  GROUPING(shipregion)  AS grpregion,
  shipcity,    GROUPING(shipcity)    AS grpcity,
  COUNT(*) AS numorders
FROM Sales.Orders
GROUP BY ROLLUP(shipcountry, shipregion, shipcity);

-- pg 158
-- Trying to eyeball stairstepped 0s and 1s is kind of a pain.
-- The GROUPING_OD function adds up powers of 2 from right to left, like Unix permissions.
  -- shipcity    = 0 or (2^0=1)
  -- shipregion  = 0 or (2^1=2)
  -- shipcountry = 0 or (2^2=4)
SELECT GROUPING_ID(shipcountry, shipregion, shipcity) AS grp_id, 
  shipcountry, shipregion, shipcity, 
  COUNT(*) AS numorders
FROM Sales.Orders
GROUP BY ROLLUP(shipcountry, shipregion, shipcity);

-- Sorting by group_id will put them in a sensible sub-total order.
-- The group_id order will be determined by the column order in the SELECT
-- clause, not the GROUP BY clause, or the GROUPING or GROUPING_ID functions.
SELECT GROUPING_ID(shipcountry, shipregion, shipcity) AS grp_id, 
  shipcountry, shipregion, shipcity, 
  COUNT(*) AS numorders
FROM Sales.Orders
GROUP BY CUBE(shipcountry, shipregion, shipcity)
-- ORDER BY shipcountry, shipregion, shipcity;
--/*
ORDER BY 
	CASE 
		WHEN shipcountry IS NULL THEN 'zzz_shipcountry'
		ELSE shipcountry
	END, 
	CASE 
		WHEN shipregion IS NULL THEN 'zzz_shipregion'
		ELSE shipregion
	END, 
	CASE 
		WHEN shipcity IS NULL THEN 'zzz_shipcity'
		ELSE shipcity
	END, 
	grp_id;
--*/

SELECT GROUPING_ID(shipcountry, shipregion, shipcity) AS grp_id, 
  shipcountry, shipregion, shipcity, 
  COUNT(*) AS numorders
FROM Sales.Orders
WHERE shipregion IS NOT NULL
GROUP BY CUBE(shipcountry, shipregion, shipcity)
 ORDER BY grp_id, shipcountry, shipregion, shipcity;
/*
ORDER BY 
	CASE 
		WHEN shipcountry IS NULL THEN 'zzz_shipcountry'
		ELSE shipcountry
	END, 
	grp_id;
*/

SELECT GROUPING_ID(shipperid, YEAR(shippeddate)) AS grp_id, 
  shipperid, YEAR(shippeddate) AS shipyear, COUNT(*) AS numorders
FROM Sales.Orders
GROUP BY GROUPING SETS
(
  (shipperid, YEAR(shippeddate)),
  (YEAR(shippeddate)), 
  (shipperid),
  (/* empty set */)
)
ORDER BY grp_id, shipperid, shipyear;
/*
	CASE 
		WHEN shipperid IS NULL THEN MAX(shipperid)+1
		ELSE shipperid
	END;
*/

-- Using UNION ALL is no good, since subqueries can't be ordered.
----------------------------------------------------------------------
SELECT shipperid, YEAR(shippeddate) AS shipyear, COUNT(*) AS numorders
FROM Sales.Orders
GROUP BY GROUPING SETS
(
  (shipperid, YEAR(shippeddate))
)
--ORDER BY shipperid, shipyear
--;

UNION ALL

SELECT NULL AS shipperid, YEAR(shippeddate) AS shipyear, COUNT(*) AS numorders
FROM Sales.Orders
GROUP BY GROUPING SETS
(
  (YEAR(shippeddate))
)
ORDER BY shipyear;

--UNION ALL

SELECT shipperid, NULL AS shipyear, COUNT(*) AS numorders
FROM Sales.Orders
GROUP BY GROUPING SETS
(
  (shipperid)
)
ORDER BY shipperid;

--UNION ALL

SELECT NULL AS shipperid, NULL AS shipyear, COUNT(*) AS numorders
FROM Sales.Orders
GROUP BY GROUPING SETS
(
  (/* empty set */)
)
--ORDER BY shipperid, shipyear
;

/* Practice */
-- pg 160
-- Exercise 1, #2
SELECT custid, COUNT(*) AS numorders
FROM Sales.Orders
WHERE shipcountry = N'Spain'
GROUP BY custid;

-- or

SELECT C.custid, COUNT(*) AS numorders
FROM Sales.Orders AS O
  INNER JOIN Sales.Customers AS C
    ON O.custid = C.custid
WHERE O.shipcountry = N'Spain'
GROUP BY C.custid, C.companyname;

-- pg 160
-- Exercise 1, #4
SELECT C.custid, C.city, COUNT(*) AS numorders
FROM Sales.Orders AS O
  INNER JOIN Sales.Customers AS C
    ON O.custid = C.custid
WHERE O.shipcountry = N'Spain'
GROUP BY C.custid, C.city;

-- pg 161
-- Exercise 2
SELECT GROUPING_ID(C.custid, C.city) AS grp_id, 
  C.custid, C.city, COUNT(*) AS numorders
FROM Sales.Orders AS O
  INNER JOIN Sales.Customers AS C
    ON O.custid = C.custid
WHERE O.shipcountry = N'Spain'
GROUP BY GROUPING SETS
(
  (C.custid, C.city), 
  (/*empty set*/)
)
ORDER BY grp_id, C.custid, C.city
;

-- OR

SELECT C.custid, C.city, COUNT(*) AS numorders
FROM Sales.Orders AS O
  INNER JOIN Sales.Customers AS C
    ON O.custid = C.custid
WHERE O.shipcountry = N'Spain'
GROUP BY GROUPING SETS
(
  (C.custid, C.city), 
  (/*empty set*/)
)
ORDER BY GROUPING_ID(C.custid, C.city), C.custid, C.city
;

-- OR

SELECT C.custid, C.city, COUNT(*) AS numorders
FROM Sales.Orders AS O
  INNER JOIN Sales.Customers AS C
    ON O.custid = C.custid
WHERE O.shipcountry = N'Spain'
GROUP BY GROUPING SETS
(
  (C.custid, C.city), 
  (/*empty set*/)
)
ORDER BY GROUPING(C.custid)
;

/* Lesson Review */
-- 1: D
-- 2: B, C, D (correct)
-- 3: A