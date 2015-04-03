-- Lesson 1 --

--pg 6
USE TSQL2012;

SELECT country
FROM HR.Employees;

--pg 7
SELECT DISTINCT country
FROM HR.Employees;

SELECT empid, lastname
FROM HR.Employees;

--pg 8
SELECT empid, lastname
FROM HR.Employees
ORDER BY empid;

SELECT empid, lastname
FROM HR.Employees
ORDER BY 1;

--pg 9
SELECT empid, firstname + ' ' + lastname
FROM HR.Employees;

SELECT empid, firstname + ' ' + lastname AS fullname
FROM HR.Employees;

--pg 11 - Exercise 1
SELECT custid, YEAR(orderdate)
FROM Sales.Orders
ORDER BY 1, 2;

--pg 12 - Exercise 2
SELECT DISTINCT custid, YEAR(orderdate) AS orderyear
FROM Sales.Orders;


-- Lesson 2 --

-- pg 14
SELECT shipperid, phone, companyname
FROM Sales.Shippers;

-- pg 16
SELECT country, YEAR(hiredate) AS yearhired, COUNT(*) AS numemployees
FROM HR.Employees
WHERE hiredate >= '20030101'
GROUP BY country, YEAR(hiredate)
HAVING COUNT(*) > 1
ORDER BY country, yearhired DESC;

-- pg 17 
-- WHERE clause is evaluated before SELECT clause, 
-- so "yearhired" doesn't exist when requested. Will fail.
SELECT country, YEAR(hiredate) AS yearhired
FROM HR.Employees
WHERE yearhired >= '2003';

-- pg 20
-- Aliases created in SELECT clause are considered to be done instantaneously,
-- in no particular order (not left-to-right), so cannot be used by other 
-- expressions. This query will fail.
SELECT country, YEAR(hiredate) AS yearhired, yearhired - 1 AS prevyear
FROM HR.Employees

-- pg 21 - Exercise 1, #2
SELECT custid, orderid
FROM Sales.Orders
GROUP BY custid;

-- pg 22 - Exercise 1, #3
SELECT custid, MAX(orderid) AS maxorderid
FROM Sales.Orders
GROUP BY custid;

-- pg 22 - Exercise 2, #1
SELECT shipperid, SUM(freight) AS totalfreight
FROM Sales.Orders
WHERE freight > 20000.00
GROUP BY shipperid;

-- pg 22 - Exercise 2, #2
SELECT shipperid, SUM(freight) AS totalfreight
FROM Sales.Orders
GROUP BY shipperid
HAVING totalfreight > 20000.00;

-- pg 23 - Exercise 2, #3
SELECT shipperid, SUM(freight) AS totalfreight
FROM Sales.Orders
GROUP BY shipperid
HAVING SUM(freight) > 20000.00;

