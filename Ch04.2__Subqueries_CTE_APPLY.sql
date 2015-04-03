/*	Lesson 2: Using Subqueries, Table Expressions, and the APPLY Operator	*/
/*	Subqueries	*/
-- Self-Contained Subqueries
/* Can be run in isolation. Subquery is run one time, and returns a result set
   that can be used in the outer query. Database engine presumably evaluates
   nested SELECT statement(s) first.
*/
-- pg 118
SELECT productid, productname, unitprice
FROM Production.Products
WHERE unitprice = 
  (SELECT MIN(unitprice)
   FROM Production.Products);
-- Self-contained ubquery returns a single scalar value.
-- Outer query uses result in an equality comparison.
-- Returns one result row.

-- pg 119
SELECT productid, productname, unitprice
FROM Production.Products
WHERE supplierid IN
  (SELECT supplierid
   FROM Production.Suppliers
   WHERE country = N'Japan');
-- Self-contained subquery returns 3-row column of results.
-- Outer query checks each Production.Products.supplierid value to see if it's
-- in the result set. Returns 6 rows. Note that supplierid isn't returned.

-- Correlated Subqueries
/* One or more values from outer query is used in subquery. Can be thought of
   as a FOR EACH loop, or cursor, where the subquery is called one time for
   each different value in the outer query.
*/
-- pg 119
SELECT categoryid, productid, productname, unitprice
FROM Production.Products AS P1
WHERE unitprice = 
  (SELECT MIN(unitprice)
   FROM Production.Products AS P2
   WHERE P2.categoryid = P1.categoryid);
-- Returns products with minimum unit price per category.
/* The subquery must be run at least once for each unique P1.categoryid value.
   For each of those, we find matching values in P2.categoryid, then find the
   one MIN(unitprice) value of that set, which the subquery returns to the 
   outer query. The outer query filters for P1.unitprice values, and adds them
   to an intermediate result set, then passes in the next P1.categoryid value
   to the subquery. When all P1.categoryid values have been processed, the
   outer query returns the final compiled (and possibly sorted) result set.
*/

-- pg 120
-- Returns customers who placed orders on Feb 12, 2007
SELECT custid, companyname
FROM Sales.Customers AS C
WHERE EXISTS
  (SELECT *
   FROM Sales.Orders AS O
   WHERE O.custid = C.custid
     AND O.orderdate = '20070212');
/* For each C.custid in outer query, the subquery filters for matching O.custid
   rows where O.orderdate is 2/12/07. A better approach would probably be to
   JOIN the two tables ON C.custid = O.custid, then filter for O.orderdate.
   Since all the filtering for the example happens in the subquery, the outer
   query uses the EXISTS keyword to accept the subquery's input. You could
   probably replace "EXISTS" with "C.custid IN", which would also look through
   the subquery's results. (No, you can't. See below.)
*/
	SELECT custid, companyname
	FROM Sales.Customers AS C
	WHERE C.custid IN
	  (SELECT *
	   FROM Sales.Orders AS O
	   WHERE O.custid = C.custid
		 AND O.orderdate = '20070212');
	-- Msg 116, Level 16, State 1, Line 7
	-- Only one expression can be specified in the select list when the subquery is not introduced with EXISTS.
	
	SELECT C.custid, C.companyname
	FROM Sales.Customers AS C
	  INNER JOIN Sales.Orders AS O
		ON O.custid = C.custid
	WHERE O.orderdate = '20070212';
	-- Returns same result as correlated subquery above.

-- pg 121
-- EXISTS predicate can be negated. Customers who did NOT place orders on 2/12:
SELECT custid, companyname
FROM Sales.Customers AS C
WHERE NOT EXISTS
  (SELECT *
   FROM Sales.Orders AS O
   WHERE O.custid = C.custid
     AND O.orderdate = '20070212');
-- Returns 89 rows.

	SELECT C.custid, C.companyname
	FROM Sales.Customers AS C
	WHERE C.custid NOT IN
	  (SELECT O.custid
	   FROM Sales.Orders AS O
	   WHERE O.orderdate = '20070212');
	-- Returns 89 rows.

	SELECT C.custid, C.companyname
	FROM Sales.Customers AS C
	
	EXCEPT
	
    SELECT O.custid, C.companyname
	FROM Sales.Customers AS C
	  INNER JOIN Sales.Orders AS O
		ON O.custid = C.custid
    WHERE O.orderdate = '20070212';
	-- Returns 89 rows.
	-- This works, but is cumbersome to write.

/*	Table Expressions	*/
-- pg 121
-- "Named queries". Don't need to be (cannot be) optimized.
-- Derived tables & Common Table Expressions (CTEs): visible only to statement
-- Views & Inline Table-valued Functions: persist in database.

-- Derived Tables
/* Defined via subquery in FROM clause: 
   SELECT * 
   FROM (SELECT col1, col2 
         FROM NormalTable) AS DerivedTable;
*/
-- pg 122
-- Justification for derived table sample, part 1.
SELECT
  ROW_NUMBER() OVER(PARTITION BY categoryid
                    ORDER BY unitprice, productid) AS rownum,
  categoryid, productid, productname, unitprice
FROM Production.Products;
-- Returns 77 rows with 8 unique categorid values.
-- Column based on ROW_NUMBER() can only be defined in SELECT clause, so we
-- can't use it as a filter in WHERE clause, because it hasn't been created
-- yet. To make it a valid filter, it must be in another (derived) table.

-- pg 123
-- Justification for derived table sample, part 2.
SELECT categoryid, productid, productname, unitprice
FROM (SELECT
	    ROW_NUMBER() OVER(PARTITION BY categoryid
						  ORDER BY unitprice, productid) AS rownum,
	    categoryid, productid, productname, unitprice
	  FROM Production.Products) AS D
WHERE rownum <=2;
-- Returns 16 rows, 2 for each categoryid value.

-- CTEs
-- pg 125
-- Reworked version of derived table above:
WITH C AS
(
  SELECT
    ROW_NUMBER() OVER(PARTITION BY categoryid
					  ORDER BY unitprice, productid) AS rownum,
    categoryid, productid, productname, unitprice
  FROM Production.Products
)
SELECT categoryid, productid, productname, unitprice
FROM C
WHERE rownum <= 2;

-- pg 126
-- Recursive form of CTE
WITH EmpsCTE AS
(
  -- Anchor member
  SELECT empid, mgrid, firstname, lastname, 0 AS distance
  FROM HR.Employees
  WHERE empid = 9
  
  UNION ALL
  
  -- Recursive member
  SELECT M.empid, M.mgrid, M.firstname, M.lastname, S.distance + 1 AS distance
  FROM EmpsCTE AS S
    JOIN HR.Employees AS M
      ON S.mgrid = M.empid
)
-- Outer query
SELECT empid, mgrid, firstname, lastname, distance
FROM EmpsCTE;

-- Views and Inline Table-Valued Functions
/* Both are basically stored SELECT queries. Functions can accept parameters,
   while views can't. Access to both can be controlled through permissions.
*/
-- pg 127 (View)
IF OBJECT_ID('Sales.RankedProducts', 'V') IS NOT NULL DROP VIEW Sales.RankedProducts;
GO
CREATE VIEW Sales.RankedProducts
AS

SELECT
  ROW_NUMBER() OVER(PARTITION BY categoryid
					ORDER BY unitprice, productid) AS rownum,
  categoryid, productid, productname, unitprice
FROM Production.Products;
GO

-- pg 127 cont'd
SELECT categoryid, productid, productname, unitprice
FROM Sales.RankedProducts
WHERE rownum <=2;
-- Returns 16 rows

select * from Sales.RankedProducts;
-- Returns 77 rows.

-- pg 128 (ITF)
IF OBJECT_ID('HR.GetManagers', 'IF') IS NOT NULL DROP FUNCTION HR.GetManagers;
GO
CREATE FUNCTION HR.GetManagers(@empid AS INT) RETURNS TABLE
AS

RETURN
  -- Recursive form of CTE
  WITH EmpsCTE AS
  (
    -- Anchor member
    SELECT empid, mgrid, firstname, lastname, 0 AS distance
    FROM HR.Employees
    WHERE empid = @empid
    
    UNION ALL
    
    -- Recursive member
    SELECT M.empid, M.mgrid, M.firstname, M.lastname, S.distance + 1 AS distance
    FROM EmpsCTE AS S
      JOIN HR.Employees AS M
        ON S.mgrid = M.empid
  )
  -- Outer query
  SELECT empid, mgrid, firstname, lastname, distance
  FROM EmpsCTE;
GO

-- pg 128 cont'd
SELECT * 
FROM HR.GetManagers(9) AS M;

/* Apply */
-- For each row in left-side table expression, applies right-side table expression.
-- Right-side expression can be correlated (depend on) value in left-side expression;
-- conceptually, right side is evaluated first. Can sometimes replace cursors.

-- Cross Apply
-- pg 130
-- OFFSET-FETCH not supported in 2008.
SELECT productid, productname, unitprice
FROM Production.Products AS P
WHERE supplierid = 1
ORDER BY unitprice, productid
OFFSET 0 ROWS FETCH FIRST 2 ROWS ONLY;
-- Use TOP instead.
SELECT TOP 2 productid, productname, unitprice
FROM Production.Products AS P
WHERE supplierid = 1
ORDER BY unitprice, productid;
-- Returns 2 rows, as requested.

-- pg 130 cont'd
-- Left-side query, stand-alone version.
SELECT *
FROM Production.Suppliers AS S
WHERE S.country = N'Japan';
-- Returns 3 rows.

-- Sample version as given in book
SELECT S.supplierid, S.companyname AS supplier, A.*
FROM Production.Suppliers AS S
  CROSS APPLY (SELECT TOP 2 productid, productname, unitprice
               FROM Production.Products AS P
               WHERE P.supplierid = S.supplierid
               ORDER BY unitprice, productid) AS A
WHERE S.country = N'Japan';
-- Doesn't return 6 rows (3 suppliers * 2 rows each), because supplier 30 has no products.

-- Can we substitute a table-valued function for the right-side table expression?
IF OBJECT_ID('Production.Get2CheapestProducts', 'IF') IS NOT NULL DROP FUNCTION Production.Get2CheapestProducts;
GO
CREATE FUNCTION Production.Get2CheapestProducts(@supplierid AS INT) RETURNS TABLE
AS

RETURN
  SELECT TOP 2 P.productid, P.productname, P.unitprice
  FROM Production.Products AS P
  WHERE P.supplierid = @supplierid
  ORDER BY unitprice, productid
  ;
GO
-- Msg 156, Level 15, State 1, Procedure Get2CheapestProducts, Line 4
-- Incorrect syntax near the keyword 'SELECT'.
-- Forgot RETURN keyword.

-- Sample version with ITF as right-side expression
SELECT S.supplierid, S.companyname AS supplier, A.*
FROM Production.Suppliers AS S
  CROSS APPLY Production.Get2CheapestProducts(S.supplierid) AS A
WHERE S.country = N'Japan';
-- Yes! It works!

-- Outer Apply
-- Same as CROSS, but also returns rows from left side that have no matching
-- rows on right, much like LEFT OUTER JOIN vs INNER JOIN.

-- pg 132
-- Sample version as given in book
SELECT S.supplierid, S.companyname AS supplier, A.*
FROM Production.Suppliers AS S
  OUTER APPLY (SELECT TOP 2 productid, productname, unitprice
               FROM Production.Products AS P
               WHERE P.supplierid = S.supplierid
               ORDER BY unitprice, productid) AS A
WHERE S.country = N'Japan';
-- Doesn't return 6 rows (3 suppliers * 2 rows each), because supplier 30 has no products.
-- Does return a fifth row instead of only four, showing NULL values for right-side columns.

-- Sample version with ITF as right-side expression
SELECT S.supplierid, S.companyname AS supplier, A.*
FROM Production.Suppliers AS S
  OUTER APPLY Production.Get2CheapestProducts(S.supplierid) AS A
WHERE S.country = N'Japan';
-- Returns same rows as book version.

/*  Practice  */
-- Exercise 1
-- pg 133
-- first, figure out what the lowest price in each category is, never mind
-- which products have that price.
SELECT P.categoryid, MIN(P.unitprice) AS mn
FROM Production.Products AS P
GROUP BY P.categoryid;

-- pg 133 cont'd
-- There can be more than one product with the same price, so after determining
-- what the minimum price is, we need to go find matches of it in the Products
-- table. We match on both the categoryid and price columns so that we aren't
-- returning products having the lowest price in some other category.
WITH MinCategoryPrice
AS
(
  SELECT P.categoryid, MIN(P.unitprice) AS mn
  FROM Production.Products AS P
  GROUP BY P.categoryid
)
SELECT P.categoryid, P.productid, P.productname, P.unitprice
FROM Production.Products AS P
  INNER JOIN MinCategoryPrice AS M
    ON P.categoryid = M.categoryid
   AND P.unitprice = M.mn;

-- Exercise 2: Return N Products with Lowest Unit Price Per Supplier
-- Use CROSS APPLY, OUTER APPLY
-- pg 134, #1 (Define function)
IF OBJECT_ID('Production.GetTopProducts', 'IF') IS NOT NULL 
DROP FUNCTION Production.GetTopProducts;
GO
CREATE FUNCTION Production.GetTopProducts(@supplierid AS INT, @n AS BIGINT) 
RETURNS TABLE
AS

RETURN
  SELECT TOP (@n) P.productid, P.productname, P.unitprice
  FROM Production.Products AS P
  WHERE P.supplierid = @supplierid
  ORDER BY P.unitprice, P.productid;
GO
-- Forgot to include object type (IF) and single quotes around parameters in OBJECT_ID input. 
-- Defined @n as INT instead of BIGINT.
-- Forgot RETURN before SELECT.
-- Argument to TOP needs to be in parentheses when using a variable value:
    -- TOP 5    - Works
    -- TOP (5)  - Works
    -- TOP @n   - Fails
    -- TOP (@n) - Works
-- Book doesn't include table alias.
-- Book uses OFFSET-FETCH instead of TOP

-- pg 134, #2 (Test function)
SELECT * FROM Production.GetTopProducts(1, 2) AS P;
-- Forgot "* FROM" portion.
-- Runs without table alias, but (I think) needs one to be a relation.

-- pg 134, #3 (CROSS APPLY)
SELECT S.supplierid, S.country
FROM Production.Suppliers AS S
  CROSS APPLY SELECT * FROM Production.GetTopProducts(S.supplierid, 2) AS P
WHERE S.country = N'Japan';
-- Missed S.companyname in SELECT list, and included S.country when not needed.
-- Selection from right-side expression still happens in topmost SELECT clause;
-- when running the function by itself, the SELECT * FROM goes immediately prior,
-- but only because there's nothing else in the statement.
-- Book uses alias "A" for function output. Stands for "All"?

SELECT S.supplierid, S.companyname AS supplier, A.*
FROM Production.Suppliers AS S
  CROSS APPLY Production.GetTopProducts(S.supplierid, 2) AS A
WHERE S.country = N'Japan';
-- Returns 4 rows.

-- pg 135, #4 (OUTER APPLY)
SELECT S.supplierid, S.companyname AS supplier, A.*
FROM Production.Suppliers AS S
  OUTER APPLY Production.GetTopProducts(S.supplierid, 2) AS A
WHERE S.country = N'Japan';
-- Returns 5 rows.

-- pg 135, #5 (Clean up)
IF OBJECT_ID('Production.GetTopProducts', 'IF') IS NOT NULL 
DROP FUNCTION Production.GetTopProducts;
GO
-- Copy/pasted from #1. Works as expected.

/*  Lesson Review */
-- pg 136
-- 1: A
-- 2: B, C
-- 3: A (Wrong. Correct answer D)
