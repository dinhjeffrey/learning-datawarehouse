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