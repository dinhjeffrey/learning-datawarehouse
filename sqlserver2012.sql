use TSQL2012;
/*
Using the REPLICATE function, 
you generate a string made of 10 zeros. 
Next you concatenate the character form of the product ID. 
Then you extract the 10 rightmost characters from the result string.
*/
select productid,
right(replicate('0',10) + cast(productid as varchar(10)), 10) AS str_productid
from production.Products
;

/*
Table attributes and their data types
empid	lastname	firstname	title	titleofcourtesy	birthdate	hiredate	address	city	region	postalcode	country	phone	mgrid
1	Davis	Sara	CEO	Ms.	1958-12-08 00:00:00.000	2002-05-01 00:00:00.000	7890 - 20th Ave. E., Apt. 2A	Seattle	WA	10003	USA	(206) 555-0101	NULL
2	Funk	Don	Vice President, Sales	Dr.	1962-02-19 00:00:00.000	2002-08-14 00:00:00.000	9012 W. Capital Way	Tacoma	WA	10001	USA	(206) 555-0100	1
3	Lew	Judy	Sales Manager	Ms.	1973-08-30 00:00:00.000	2002-04-01 00:00:00.000	2345 Moss Bay Blvd.	Kirkland	WA	10007	USA	(206) 555-0103	2
*/

/*
empid	int		4	PK 	not null  (all of columns are not null)
lastname	nvarchar	20
firstname	nvarchar	10	
title	nvarchar	30	
titleofcourtesy	nvarchar	25
birthdate	datetime	
hiredate	datetime
address		nvarchar	60	
city	nvarchar	15
region	nvarchar	15	
postalcode	nvarchar	10	
country		nvarchar	15	
phone	nvarchar	24	
mgrid		int		4	FK 	null
*/


/* Standard SQL Code
use COALESCE and not ISNULL, 
use CURRENT_TIMESTAMP and not GETDATE, 
and use CASE and not IIF.
*/



/*
Using the REPLICATE function, 
you generate a string made of 10 zeros. 
Next you concatenate the character form of the product ID. 
Then you extract the 10 rightmost characters from the result string.
*/

/*
The subquery uses a correlation in the                                                                                              category ID is equal to the one in the outer row. So when the outer row has category ID 1,                                                                                                 when the outer row has category ID 2, the inner query returns the minimum unit price out of                                                    
*/

SELECT categoryid, productid, productname, unitprice
FROM Production.Products AS P1
WHERE unitprice =
  (SELECT MIN(unitprice)
   FROM Production.Products AS P2
   WHERE P2.categoryid = P1.categoryid)
   ;



/*
The thing with the ROW_NUMBER function—and window functions in general—is that they are only allowed in the SELECT and ORDER BY clauses of a query. So, what if you want to                                                                                                                                                                                           to return the two products with the lowest unit prices, with the product ID used as a tiebreak- er. You are not allowed to refer to the ROW_NUMBER function in the query’s WHERE clause. Remember also that according to logical query processing, you’re not allowed to refer to a column alias that was assigned in the SELECT list in the WHERE clause, because the WHERE clause is conceptually evaluated before the SELECT clause.
You can circumvent the restriction by using a table expression. You write a query such as the previous query that computes the window function in the SELECT clause:                                                                                           and refer to the column alias in the outer query’s WHERE clause, as follows.
*/

SELECT categoryid, productid, productname, unitprice
FROM (SELECT
        ROW_NUMBER() OVER(PARTITION BY categoryid
                          ORDER BY unitprice, productid) AS rownum,
        categoryid, productid, productname, unitprice
      FROM Production.Products) AS D
WHERE rownum <= 2;


/*
With CTEs, you first name the CTE, then specify the inner query, and then the outer query - a much more modular approach.
*/

WITH <CTE_name>
AS
(
  <inner_query>
)
<outer_query>;

/*
As you can see, it’s a similar concept to derived tables, except the inner query is not defined in the middle of the outer query; instead you define the 
inner query from start to end—then the outer query—from start to end. This design leads to much clearer code that is easier to understand.
*/

WITH C AS (
  SELECT
    ROW_NUMBER() OVER(PARTITION BY categoryid
                      ORDER BY unitprice, productid) AS rownum,
    categoryid, productid, productname, unitprice
  FROM Production.Products
)
SELECT categoryid, productid, productname, unitprice
FROM C
WHERE rownum <= 2;

/*
As you can see, the anchor member returns the row for employee 9. Then the recursive 
member is invoked repeatedly, and in each round joins the previous result set with the HR.Employees table 
to return the direct manager of the employee from the previous round.                                                                                                                                                                                          the anchor member (the row for employee 9) and all invocations of the recursive member (all managers above employee 9).
*/

WITH EmpsCTE AS
(
  SELECT empid, mgrid, firstname, lastname, 0 AS distance
  FROM HR.Employees
  WHERE empid = 9
UNION ALL
  SELECT M.empid, M.mgrid, M.firstname, M.lastname, S.distance + 1 AS distance
  FROM EmpsCTE AS S
    JOIN HR.Employees AS M
      ON S.mgrid = M.empid
)
SELECT empid, mgrid, firstname, lastname, distance
FROM EmpsCTE
;

/*
Stored objects in database for re-usability:

Views - doesn’t accept input parameters
Inline Table-Valued Functions - accepts input parameters
*/

/*
Definition is stored in database; not the result set of the view.
*/

if object_id('sales.rankedproducts', 'V') is not null drop view sales.rankedproducts
;
go
create view sales.rankedproducts
as

select 
	row_number() over(partition by categoryid
		order by unitprice, productid) as rownum,
		categoryid, productid, productname, unitprice
from production.products
;
go

/*
What’s special about the CROSS APPLY op- erator as compared to OUTER APPLY 
is that if the right table expression returns an empty set for a left row, the left row isn’t returned. 
*/

/* What is the difference between self-contained and correlated subqueries?
Self-contained subqueries are independent of the outer query, 
whereas cor- related subqueries have a reference to an element from the table in the outer query.
*/

/* What is the difference between APPLY and JOIN operators?
With a JOIN operator, both inputs represent static relations. With APPLY, the left side is a static relation, 
but the right side can be a table expression with correlations to elements from the left table.
*/

/*
The next step in the solution is to de ne a CTE based on the previous query, 
and then join the CTE to the Production.Products table to return per each category the products with the minimum unit price. 
This step can be achieved with the following code.
*/
with CatMin as
(
select categoryid, min(unitprice) as mn
from production.products
group by categoryid
)
select p.categoryid, p.productid, p.productname, p.unitprice
from production.products as p
	inner join CatMin as m
	on p.categoryid = m.categoryid
	and p.unitprice = m.mn
;


/*
Define an inline table-valued function that accepts a supplier ID as input (@supplierid), in addition to a number (@n), 
and returns the @n products with the lowest prices for the input supplier. 
In case of ties in the unit price, use the product ID as the tiebreaker. Use the following code to de ne the function.
*/

IF OBJECT_ID('Production.GetTopProducts', 'IF') IS NOT NULL DROP FUNCTION
Production.GetTopProducts;
go
create function Production.GetTopProducts(@supplierid as int, @n as bigint)
returns table
as

return 
	select productid, productname, unitprice
	from production.products 
	where supplierid = @supplierid
	order by unitprice, productid
	offset 0 rows fetch first @n rows only;
go

select * from production.GetTopProducts(1,2) as P;


/*
Next, return per each supplier from Japan the two products with the lowest prices. 
To achieve this, use the CROSS APPLY operator, with Production.Suppliers as the left side and 
the Production.GetTopProducts function as the right side, as follows.
*/

select s.supplierid, s.companyname as supplier, a.*
from production.suppliers as s
	cross apply Production.GetTopProducts(s.supplierid, 2) as a
where s.country = N'Japan'
;


/* Chapter 5
The lessons in this chapter cover grouped queries and pivoting and unpivoting of data. 
Pivoting can be considered a specialized form of grouping, and unpivoting can be consid- ered the inverse of pivoting. 
This chapter also covers windowed queries.

Grouped queries return one result row per group, and because the query de nes only one group, it returns only one row in the result set.
ie. count(*), group by, group functions
*/

/*
suppose that you need to group only shipped orders by shipper ID and shipping year, and  filter only groups having fewer than 100 orders.
*/
select shipperid, year(shippeddate) as shippedyear, count(*) as numorders
from sales.orders
where shippeddate is not null
group by shipperid, year(shippeddate)
having count(*) < 100
;




/*
 What makes a query a grouped query?
2. What are the clauses that you can use to de ne multiple grouping sets in the
same query?
Quick Check Answer
1. When you use an aggregate function, a GROUP BY clause, or both. 2. GROUPING SETS, CUBE, and ROLLUP.
*/

select c.custid, c.city, count(*) as numorders
from sales.customers as c
	inner join sales.orders as o
		on c.custid = o.custid
	where c.country = N'Spain'
	group by grouping sets ((c.custid, c.city), () )
	order by grouping(c.custid);


/*
Chapter 5, Lesson 2: Pivot and Unpivot
*/
WITH PivotData AS
(
  SELECT
    custid   , -- grouping column
    shipperid, -- spreading column
    freight    -- aggregation column
  FROM Sales.Orders
)
SELECT custid, [1], [2], [3]
FROM PivotData
  PIVOT(SUM(freight) FOR shipperid IN ([1],[2],[3]) ) AS P;


