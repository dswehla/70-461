USE TSQL2012;

-- pg 102 (add new Supplier)
INSERT INTO Production.Suppliers
	(companyname, contactname, contacttitle, address, city, postalcode, country, phone)
	VALUES(N'Supplier XYZ', N'Jiru', N'Head of Security', N'42 Sekimai Musashino-shi', 
	N'Tokyo', N'01759', N'Japan', N'(02) 4311-2609');

/*	Lesson 1: Using Joins*/
-- Cross Joins
-- pg 103
SELECT D.n AS theday, S.n AS shiftno
FROM dbo.Nums AS D
	CROSS JOIN dbo.Nums AS S
WHERE D.n <= 7
  AND S.n <= 3
ORDER BY theday, shiftno;

select * from Nums; -- One column, 100,000 rows.

-- Inner Joins
-- pg 105
SELECT 
  S.companyname AS supplier, S.country, 
  P.productid, P.productname, P.unitprice
FROM Production.Suppliers AS S
  INNER JOIN Production.Products AS P
    ON S.supplierid = P.supplierid
WHERE S.country = N'Japan';

-- pg 107
SELECT 
  S.companyname AS supplier, S.country, 
  P.productid, P.productname, P.unitprice
FROM Production.Suppliers AS S
  INNER JOIN Production.Products AS P
    ON S.supplierid = P.supplierid
    AND S.country = N'Japan'; -- Using AND instead of WHERE
    -- Makes no difference in INNER JOIN, but would affect OUTER, so just don't do it.

SELECT E.empid, 
  E.firstname + N' ' + E.lastname AS emp,
  M.firstname + N' ' + M.lastname AS mgr
FROM HR.Employees AS E
  INNER JOIN HR.Employees AS M
    ON E.mgrid = M.empid;
-- CEO Sarah Davis not included in Employee (emp) column, because she has no supervisor.

-- Outer Joins
-- pg 109
SELECT
  S.companyname AS supplier, S.country, 
  P.productid, P.productname, P.unitprice	-- 5. Select columns from filtered results.
FROM Production.Suppliers AS S				-- 1. Return all rows from Suppliers.
  LEFT OUTER JOIN Production.Products AS P	-- 2. Return only rows in Products
    ON S.supplierid = P.supplierid			-- 3. that have a matching supplierID.
WHERE S.country = N'Japan';					-- 4. Filter returned rows for Suppliers in Japan.
-- Returns NULLs in Product columns for Supplier XYZ, added at beginning of chapter.

-- pg 110
SELECT
  S.companyname AS supplier, S.country, 
  P.productid, P.productname, P.unitprice	-- 5. Select columns from filtered results.
FROM Production.Suppliers AS S				-- 1. Return all rows (including non-Japan) from Suppliers.
  LEFT OUTER JOIN Production.Products AS P	-- 2. Return only rows in Products
    ON S.supplierid = P.supplierid			-- 3.  - that have a matching supplierID in Supplier,
   AND S.country = N'Japan';				-- 4.  - and where the Supplier is in Japan.
-- Returns NULLs in Product columns for 
--  - Japanese Supplier XYZ, which has no matching Products, and
--  - Products that are not Japanese, even though Suppliers have matching products.

SELECT E.empid, 
  E.firstname + N' ' + E.lastname AS emp,
  M.firstname + N' ' + M.lastname AS mgr
FROM HR.Employees AS E
  LEFT OUTER JOIN HR.Employees AS M	-- "LEFT JOIN" works as well. Be specific anyway, though.
    ON E.mgrid = M.empid;
-- CEO Sarah Davis IS included in Employee (emp) column, even though she has no supervisor,
-- because we use LEFT JOIN to ensure all employees are listed.

-- pg 112
/* FULL OUTER JOIN returns matching rows of inner join, plus
   remaining rows of left table with NULLs for right-table fields, and
   remaining rows of right table with NULLs for left-table fields.
   Different from CROSS JOIN (Cartesian) in that is doesn't return 
   every possible combination.
*/

-- INNER JOIN (or just JOIN)
-- Returned row count: 77 
SELECT S.supplierid, P.productid
FROM Production.Suppliers AS S
  INNER JOIN Production.Products AS P
    ON S.supplierid = P.supplierid;

-- LEFT OUTER JOIN (or LEFT JOIN)
-- Returned row count: 78
SELECT S.supplierid, P.productid
FROM Production.Suppliers AS S
  LEFT OUTER JOIN Production.Products AS P
    ON S.supplierid = P.supplierid;

-- RIGHT OUTER JOIN (or RIGHT JOIN)
-- Returned row count: 77
SELECT S.supplierid, P.productid
FROM Production.Suppliers AS S
  RIGHT OUTER JOIN Production.Products AS P
    ON S.supplierid = P.supplierid;

-- FULL OUTER JOIN (or FULL JOIN)
-- Returned row count: 78
SELECT S.supplierid, P.productid
FROM Production.Suppliers AS S
  FULL OUTER JOIN Production.Products AS P
    ON S.supplierid = P.supplierid;

-- CROSS JOIN (aka Cartesian Product)
-- Returned row count: 2310
SELECT S.supplierid, P.productid
FROM Production.Suppliers AS S
  CROSS JOIN Production.Products AS P;

-- CROSS JOIN (aka Cartesian Product)
-- Returned row count: error
SELECT S.supplierid, P.productid
FROM Production.Suppliers AS S
  CROSS JOIN Production.Products AS P
    ON S.supplierid = P.supplierid;
-- Msg 156, Level 15, State 1, Line 4
-- Incorrect syntax near the keyword 'ON'.

-- MultiJoin Queries
-- pg 113
SELECT
  S.companyname AS supplier, S.country, 	-- 7. Select columns from filtered results.
  P.productid, P.productname, P.unitprice,
  C.categoryname
FROM Production.Suppliers AS S				-- 1. Return all rows from Suppliers.
  LEFT OUTER JOIN Production.Products AS P	-- 2. Return only rows in Products
    ON S.supplierid = P.supplierid			-- 3. that match on supplierID.
  INNER JOIN Production.Categories AS C		-- 4. From the current set and from Categories, 
    ON C.categoryid = P.categoryid			-- 5. return only rows that match on categoryid.
WHERE S.country = N'Japan';					-- 6. Filter returned rows for Suppliers in Japan.
-- Does not return anything for Company XYZ

SELECT
  S.companyname AS supplier, S.country, 	-- 8. Select columns from filtered results.
  P.productid, P.productname, P.unitprice,
  C.categoryname
FROM Production.Suppliers AS S				-- 1. Return all rows from Suppliers.
  LEFT OUTER JOIN							-- 2. Pause to get results from Product-Category.
    (Production.Products AS P					-- 3. Return only rows in Products
       INNER JOIN Production.Categories AS C	-- 4. and from Categories
         ON C.categoryid = P.categoryid)		-- 5. that match on categoryid. From those rows,
    ON S.supplierid = P.supplierid			-- 6. return matches on supplierID, and NULLs.
WHERE S.country = N'Japan';					-- 7. Filter returned rows for Suppliers in Japan.
-- Returns record for Company XYZ, sa expected.

-- Need for parentheses can be removed by changing the JOIN order.
SELECT
  S.companyname AS supplier, S.country,
  P.productid, P.productname, P.unitprice,
  C.categoryname 					-- 9. Select columns from filtered results.
FROM 
  Production.Products AS P			-- 1. From the Products table, 
    INNER JOIN						-- 3. select only rows from each side 
  Production.Categories AS C		-- 2. and from Categories, 
    ON C.categoryid = P.categoryid	-- 4. that match on categoryid. From Product-Categories, 
    RIGHT OUTER JOIN				-- 6. select all Suppliers, and only Product-Categories
  Production.Suppliers AS S			-- 5. and from Suppliers,
    ON S.supplierid = P.supplierid	-- 7. that match on supplierID.
WHERE S.country = N'Japan';			-- 8. Filter returned rows for Suppliers in Japan.
-- Returns record for Company XYZ, aS expected.

-- pg 114
-- Exercise 1: Match Customers and Orders with Inner Joins
SELECT C.contactname, O.orderid
FROM Sales.Customers AS C
  INNER JOIN Sales.Orders AS O
    ON C.custid = O.custid;
-- Returns 830 rows
-- Got this on my own. Book adds C.companyname and O.orderdate

-- pg 115
-- Exercise 2: Match Customers and Orders with Outer Joins
-- Include Customers without Orders.
SELECT C.contactname, C.companyname, O.orderid, O.orderdate
FROM Sales.Customers AS C
  LEFT OUTER JOIN Sales.Orders AS O
    ON C.custid = O.custid;
-- Returns 832 rows (830+2)

-- Include only Customers with no Orders.
SELECT C.contactname, C.companyname, O.orderid, O.orderdate
FROM Sales.Customers AS C
  LEFT OUTER JOIN Sales.Orders AS O
    ON C.custid = O.custid
WHERE O.orderid IS NULL;
-- Returns 2 rows (832-830)

-- Include all Customers, match only Orders from Feb 2008.
SELECT C.contactname, C.companyname, O.orderid, O.orderdate
FROM Sales.Customers AS C
  LEFT OUTER JOIN Sales.Orders AS O
    ON C.custid = O.custid
WHERE O.orderdate >= 2008-02-01
  AND O.orderdate < 2008-03-01;
-- Returns 0 rows: FAIL

-- Include all Customers, match only Orders from Feb 2008.
SELECT C.contactname, C.companyname, O.orderid, O.orderdate
FROM Sales.Customers AS C
  LEFT OUTER JOIN Sales.Orders AS O
    ON C.custid = O.custid
WHERE O.orderdate >= '2008-02-01'
  AND O.orderdate < '2008-03-01';
-- Returns 54 rows, no NULLS: Wrote after figuring out correct version.
-- Adding straight quotes to dates filters dates as expected, but
-- also removes NULL dates, which we want to keep.

-- Include all Customers, match only Orders from Feb 2008.
SELECT C.contactname, C.companyname, O.orderid, O.orderdate
FROM Sales.Customers AS C
  LEFT OUTER JOIN Sales.Orders AS O
    ON O.orderdate >= 2008-02-01
   AND O.orderdate <  2008-03-01;
-- Returns 91 rows, all ORDER values NULL: FAIL

-- Include all Customers, match only Orders from Feb 2008.
SELECT C.contactname, C.companyname, O.orderid, O.orderdate
FROM Sales.Customers AS C
  LEFT OUTER JOIN Sales.Orders AS O
    ON C.custid = O.custid
   AND O.orderdate >= 2008-02-01
   AND O.orderdate <  2008-03-01;
-- Returns 91 rows, all ORDER values NULL: FAIL

-- Include all Customers, match only Orders from Feb 2008.
SELECT C.contactname, C.companyname, O.orderid, O.orderdate
FROM Sales.Customers AS C
  LEFT OUTER JOIN Sales.Orders AS O
    ON C.custid = O.custid
   AND O.orderdate >= '2008-02-01'
   AND O.orderdate <  '2008-03-01';
-- Returns 110 rows, with mix of NULL and February Order values: PASS
-- Nearly identical to above, except for straight quotes around dates.

-- Lesson Review
-- pg 117
-- 1. D
-- 2. C, D
-- 3. A
