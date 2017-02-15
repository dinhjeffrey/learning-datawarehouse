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

/*
why use table expression with pivot?
By defining
a table expression as was shown in the recommended solution, you control which columns will be used as the grouping columns. 
If you return custid, shipperid, and freight in the table expression, and use the last two as the spreading and aggregation elements, 
respectively, the PIVOT operator implicitly assumes that custid is the grouping element. Therefore, it groups the data by custid, and as a result, 
returns a single row per customer.
*/

/* 
unpivot
*/
SELECT custid, shipperid, freight
FROM Sales.FreightTotals
  UNPIVOT( freight FOR shipperid IN([1],[2],[3]) ) AS U;

/*
pivot - rows -> columns
unpivot - columns -> rows
language constructs? table operators
*/


/*
returns the maximum shipping date for each order year and shipper ID
*/

with PivotData as 
(
select
	year(orderdate) as orderyear, --grouping column
	shipperid, --spreading column
	shippeddate -- aggregation column
from sales.orders
)
select orderyear, [1], [2], [3]
from PivotData
	pivot( max(shippeddate) for shipperid in ([1],[2],[3]) ) as p; 

/*
Window function
One of the benefits of using window functions is that unlike grouped queries, windowed queries do not hide the detail—they return a row for every underlying query’s row. 
This means that you can mix detail and aggregated elements in the same query, and even in the same expression. Using the OVER clause, you de ne a set of rows for the function 
to work with per each underlying row. In other words, a windowed query de nes a window of rows per each function and row in the underlying query.
*/

SELECT custid, orderid,
  val,
  SUM(val) OVER(PARTITION BY custid) AS custtotal,
  SUM(val) OVER() AS grandtotal
FROM Sales.OrderValues;

/*
Framing - Window aggregate filtering option
Window aggregate functions support another  filtering option called framing. The idea
is that you define ordering within the partition by using a window order clause, 
and then based on that order, you can confine a frame of rows between two delimiters. 
You define the delimiters by using a window frame clause. The window frame clause requires
 a window order clause to be present because a set has no order, and without order, limiting rows 
 between two delimiters would have no meaning.


 With the ROWS window frame unit, you can indi- cate the delimiters as one of three options:
■  UNBOUNDED PRECEDING or FOLLOWING, meaning the beginning or end of the parti- tion, respectively
■  CURRENT ROW, obviously representing the current row
■  <n> ROWS PRECEDING or FOLLOWING, meaning n rows before or after the current,
respectively
*/

/*
As an example, suppose that you wanted to query the Sales.OrderValues view and com- pute the running total values from the 
beginning of the current customer’s activity until the current order. You need to use the SUM aggregate. You partition the 
window by custid. You order the window by orderdate, orderid. You then frame the rows from the beginning of the 
partition (UNBOUNDED PRECEDING) until the current row. Your query should look like the following.
*/

select custid, orderid, orderdate, val,
	sum(val) over(partition by custid
			order by orderdate, orderid
			rows between unbounded preceding
				 and current row) as runningtotal
from sales.ordervalues;

/*
window ranking functions

T-SQL supports four window ranking functions: ROW_NUMBER, RANK, DENSE_RANK, and NTILE.
*/


SELECT custid, orderid, val,
  ROW_NUMBER() OVER(ORDER BY val) AS rownum,
  RANK()       OVER(ORDER BY val) AS rnk,
  DENSE_RANK() OVER(ORDER BY val) AS densernk,
  NTILE(100)   OVER(ORDER BY val) AS ntile100
FROM Sales.OrderValues;

/*
window offset functions

T-SQL supports the following window offset functions: LAG, LEAD, FIRST_VALUE, and LAST_VALUE.
*/

select custid, orderid, val,
	lag(val) over(partition by custid
		order by orderdate, orderid)as prev_val,
	lead(val) over(partition by custid
		order by orderdate, orderid) as next_val
	from sales.OrderValues;

select custid, orderid, orderdate, val,
	first_value(val) over(partition by custid
		order by orderdate, orderid
		rows between unbounded preceding
			and current row) as first_val,
	LAST_VALUE(val) over(partition by custid
		order by orderdate, orderid
		rows between current row
			and unbounded following) as last_val
	from sales.OrderValues;

/*
1. What are the clauses that the different types of window functions support?
-> Partitioning, ordering, and framing clauses.

2. What do the delimiters UNBOUNDED PRECEDING and UNBOUNDED FOLLOW-
ING represent?
-> The beginning and end of the partition, respectively.
*/


/* exercise 1 Use Window aggregate Functions
Write a query against the Sales.OrderValues view that returns per each customer and 
order the moving average value of the customer's last three orders
*/

select custid, orderid, orderdate, val,
	avg(val) over(partition by custid
		order by orderdate, orderid
		rows between 2 preceding
			and current row) as movingavg
	from sales.OrderValues;

/*
write a query against the Sales.Orders table, and  filter the three orders with the highest freight values
 per each shipper using orderid as the tiebreaker.
*/

with c as
(
	select shipperid, orderid, freight,
		row_number() over(partition by shipperid
				order by freight desc, orderid) as rownum
	from sales.orders
)
select shipperid, orderid, freight
from c
where rownum <= 3
order by shipperid, rownum;


/*
You need to compute the differ- ence between the current order value and the value of the customer's previous order, 
in addition to the difference between the current order value and the value of the customer's next order.
*/

select custid, orderid, orderdate, val,
	val - lag(val) over(partition by custid
		order by orderdate, orderid) as diffprev,
	val - lead(val) over(partition by custid
		order by orderdate, orderid) as diffnext
	from sales.OrderValues;

/*
Lesson Summary
■  Window functions perform data analysis computations. They operate on a set of rows de ned for each underlying 
	row by using a clause called OVER.
■  Unlike grouped queries, which hide the detail rows and return only one row per group, windowed queries 
	do not hide the detail. They return a row per each row in the underlying query, and allow mixing detail 
	elements and window functions in the same expressions.
■  T-SQL supports window aggregate, ranking, and offset functions. All window functions support window 
	partition and window order clauses. Aggregate window functions, in addition to FIRST_VALUE and LAST_VALUE, 
	also support a window frame clause.
*/

/* Chapter 6: Querying full text data
Can you store indexes from the same full-text catalog to different  legroups? Quick Check Answer
■  Yes. A full-text catalog is a virtual object only; full-text indexes are physical ob- jects. You can store each full-text index from the same catalog to a different  le group.
*/

/* CONTAINS and FREETEXT
 How do you search for synonyms of a word with the CONTAINS predicate? 2. Which is a more speci c predicate, CONTAINS or FREETEXT?
Quick Check Answers
1. You have to use the CONTAINS(FTcolumn, ‘FORMSOF(THESAURUS, SearchWord1)’) syntax.
2. You use the CONTAINS predicate for more speci c searches.

*/

/*

■  How many full-text search and how many semantic search functions are supported by SQL Server?
Quick Check Answer
■  SQL Server supports two full-text search and three semantic search functions
*/

/*
XML
*/

WITH XMLNAMESPACES('TK461-CustomersOrders' AS co)
SELECT [co:Customer].custid AS [co:custid],
 [co:Customer].companyname AS [co:companyname],
 [co:Order].orderid AS [co:orderid],
 [co:Order].orderdate AS [co:orderdate]
FROM Sales.Customers AS [co:Customer]
 INNER JOIN Sales.Orders AS [co:Order]
  ON [co:Customer].custid = [co:Order].custid
WHERE [co:Customer].custid <= 2
  AND [co:Order].orderid %2 = 0
ORDER BY [co:Customer].custid, [co:Order].orderid
FOR XML AUTO, ELEMENTS, ROOT('CustomersOrders');

/*
How can you get an XSD schema together with an XML document from your SELECT statement?
Quick Check Answer
■  You should use the XMLSCHEMA directive in the FOR XML clause.
*/

/*
1. What do you do in the return clause of the FLWOR expressions? 
2. What would be the result of the expression (12, 4, 7) != 7?
Quick Check Answers
1. In the return clause, you format the resulting XML of a query. 
2. The result would be true.
*/

use TSQL2012;

DECLARE @x AS XML;
SET @x = N'
<CustomersOrders>
  <Customer custid="1">
    <!-- Comment 111 -->
    <companyname>Customer NRZBB</companyname>
    <Order orderid="10692">
      <orderdate>2007-10-03T00:00:00</orderdate>
    </Order>
    <Order orderid="10702">
      <orderdate>2007-10-13T00:00:00</orderdate>
    </Order>
    <Order orderid="10952">
      <orderdate>2008-03-16T00:00:00</orderdate>
    </Order>
  </Customer>
  <Customer custid="2">
    <!-- Comment 222 -->
    <companyname>Customer MLTDN</companyname>
    <Order orderid="10308">
      <orderdate>2006-09-18T00:00:00</orderdate>
    </Order>
    <Order orderid="10952">
      <orderdate>2008-03-04T00:00:00</orderdate>
    </Order>
  </Customer>
</CustomersOrders>';
/*
Write a query that selects Customer nodes with child nodes. Select principal nodes (elements in this context) only. The result should be similar to the abbreviated result here.
1. Principal nodes
--------------------------------------------------------------------------------
<companyname>Customer NRZBB</companyname><Order orderid="10692"><orderdate>2007-
Use the following query to get the desired result.
*/
SELECT @x.query('CustomersOrders/Customer/*')
       AS [1. Principal nodes];

/*
 2. All nodes
      --------------------------------------------------------------------------------
      <!-- Comment 111 --><companyname>Customer NRZBB</companyname><Order orderid="106
*/

select @x.query('CustomersOrders/Customer/node()')
	as [2. all nodes];


/*
nodes

a. Asterisk (*)
B. comment()
c. node()
D. text()

E. value()

A. With the asterisk (*), you retrieve all principal nodes. 
B. With comment(), you retrieve comment nodes.
c. You use the node() node-type test to retrieve all nodes. 
D. With text(), you retrieve text nodes.

E. retrieve scalar values
*/

/*
XML Indexes

■ path This secondary XML index is especially useful if your queries specify path ex- pressions. It speeds up the exist() method better than the Primary XML index. Such an index also speeds up queries that use value() for a fully speci ed path.
■ vaLue This secondary XML index is useful if queries are value-based and the path is not fully speci ed or it includes a wildcard.
■ prOperty This secondary XML index is very useful for queries that retrieve one or more values from individual XML instances by using the value() method.
*/

/*
Write a query that retrieves the  rst customer name as a scalar value. The result should be similar to the result here.
    First Customer Name
    --------------------
    Customer NRZBB
*/

select @x.value('(/CustomersOrders/Customer/companyname)[1]',
	'NVARCHAR(20)')
	as [First Customer Name];

/*
Now check whether companyname and address nodes exist under the Customer node. The result should be similar to the result here.
Company Name Exists Address Exists 
------------------- -------------- 
1					0
*/

select @x.exist('(/CustomersOrders/Customer/companyname)')
	as [Company Name Exists],
	@x.exist('(/CustomersOrders/Customer/address)')
	as [Address Exists];

/*
Return all orders for the  rst customer as XML.
*/

select @x.query('//Customer[@custid=1]/Order')
	as [Customer 1 orders];

/*
Shred all orders information for the  rst customer.
*/

select T.c.value('./@orderid[1]', 'INT') as [Order Id],
	T.c.value('./orderdate[1]', 'DATETIME') as [Order Date]
	from @x.nodes('//Customer[@custid=1]/Order')
	as T(c);

/*
Update the name of the  first customer and then retrieve the new name
*/

set @x.modify('replace value of 
	/CustomersOrders[1]/Customer[1]/companyname[1]/text()[1]
	with "New Company Name"');
select @x.value('(/CustomersOrders/Customer/companyname)[1]',
	'NVARCHAR(20)')
	as [First Customer New Name];


/*
Nodes:
You use the modify() method to update XML data.
You use the nodes() method to shred XML data.
You use the exist() method to test whether a node exists.
You use the value() method to retrieve a scalar value from XML data.
*/


/*
1. How would you make the schema of the Products table dynamic?
2. How would you ensure that at least basic constraints would be enforced?

1. You could use the XML data type column to store the variable attributes in XML format.
2. You could validate the XML against an XML schema collection.
*/

-- Create table Production.Categories

go 
create table production.categoriestest
(
categoryid int not null identity
) 
go

alter table production.categoriestest
	add categoryname nvarchar(15) not null;
go
alter table production.categoriestest
	add description nvarchar(200) not null;
go

-- select * from Production.categoriestest

/* 
Now you attempt an insert into the copy table from the original table, but the insert will fail. So
we gotta use IDENTITY_INSERT ON, which allows a row to be inserted with an explicit identity value.
*/

set identity_insert production.categoriestest on;
insert production.categoriestest (categoryid, categoryname, description)
	select categoryid, categoryname, description
	from production.categories;
go
set identity_insert production.categoriestest off;
go


/*
Practice
*/

use TSQL2012;

-- Create table Production.CategoriesTest
create table production.categoriestest
(
	categoryid int not null identity,
	categoryname nvarchar(15) not null,
	description nvarchar(200) not null,
);

-- Populate the table Production.CategoriesTest
set identity_insert production.categoriestest on;
insert production.categoriestest (categoryid, categoryname, description)
	select categoryid, categoryname, description
	from production.categories;
go
set identity_insert production.categoriestest off;
go

-- make column longer
alter table production.categoriestest
	alter column description nvarchar(500);
go

-- set a value in description to null
UPDATE Production.CategoriesTest
        SET description = 'seafood and fish'
        WHERE categoryid = 8;
GO

-- alter table to allow null values
alter table production.categoriestest
	alter column description nvarchar(500) not null;
go

-- clean up
if object_id('production.categoriestest', 'U') is not null
	drop table production.categoriestest;
go

select * from Production.categoriestest;


-- lists all primary keys in db
SELECT *
FROM sys.key_constraints
WHERE type = 'pk';

--
SELECT *
FROM sys.indexes
WHERE object_id = OBJECT_ID('Production.Categories') AND name = 'PK_Categories';

-- unique constraint, similar to primary key. They both create unique indexes
alter table production.categories 
	add constraint UC_Categories unique (categoryname);
go

select * from production.Categories

/*
What types of views are available in T-SQL?

regular views, indexed views, and partitioned views
*/

/*
 1. What type of data does an inline function return? 
 2. What type of view can an inline function simulate?
Quick Check Answer
1. Inline functions return tables, and accordingly, are often referred to as inline table-valued functions.
2. An inline table-valued function can simulate a parameterized view—that is, a view that takes parameters.
*/

/*
views
*/

GO
CREATE VIEW Sales.OrderTotalsByYear
  WITH SCHEMABINDING
AS
SELECT
  YEAR(O.orderdate) AS orderyear,
  SUM(OD.qty) AS qty
FROM Sales.Orders AS O
  JOIN Sales.OrderDetails AS OD
    ON OD.orderid = O.orderid
GROUP BY YEAR(orderdate);
GO

-- create view
go 
create view sales.ordertotalsbyyear
	with schemabinding
as 
select
	year(o.orderdate) as orderyear,
	sum(od.qty) as qty
from sales.orders as o
	join sales.orderdetails as od
		on od.orderid = o.orderid
group by year(orderdate);
go

-- SCHEMABINDING, which guarantees that the underlying table structures cannot be altered without dropping the view.


-- Turn this into a view called sales.Ordertotalsbyyearcustship.
if object_id(N'sales.ordertotalsbyyearcustship', N'V') is not null
	drop view sales.OrderTotalsByYearcustship;
go
create view sales.ordertotalsbyyearcustship
	with schemabinding
as
select
c.companyname as customercompany,
s.companyname as shippercompany,
year(o.orderdate) as orderyear,
sum(od.qty) as qty,
cast(sum(od.qty * od.unitprice * (1 - od.discount))
	as numeric(12, 2)) as val
from sales.orders as o
	join sales.orderdetails as od
	on od.orderid = o.orderid
	join sales.customers as c
	on o.custid = c.custid
	join sales.shippers as s
	on o.shipperid = s.shipperid
	group by year(o.orderdate), c.companyname, s.companyname;
go
 
select * from sales.ordertotalsbyyearcustship;

-- drop view
if object_id('sales.ordertotalsbyyearcustship', N'V') is not null
	drop view sales.ordertotalsbyyearcustship;

/*
synonyms

1. Does a synonym store T-SQL or any data? 
2. Can synonyms be altered?
Quick Check Answer
1. No, a synonym is just a name. All that is stored with a synonym is the object it refers to.
2. No, to change a synonym, you must drop and recreate it.

*/

/*
synonym

--Create a special schema for reports. 
create schema reports authorization dbo;
go

-- Create a synonym for the Sales.CustOrders view in the TSQL2012 database. Look  first at the data.
 SELECT custid, ordermonth, qty FROM Sales.CustOrders;

-- You have determined that the data actually shows the customer ID, then the total of the qty column, by month. Therefore, create the totalcustQtybyMonth synonym and test it.
create synonym reports.totalcustqtybymonth for sales.custorders;
select custid, ordermonth, qty from reports.totalcustqtybymonth;     



*/


/*
synonym 

■ A synonym is a name that refers to another database object such as a table, view, func- tion, or stored procedure.
■ No T-SQL code or any data is stored with a synonym. Only the object referenced is stored with a synonym.
■ Synonyms are scoped to a database, and therefore are in the same namespace as the objects they refer to. Consequently, you cannot name a synonym the same as any other database object.
■ Synonym chaining is not allowed; a synonym cannot refer to another synonym.
■ Synonyms do not expose any metadata of the objects they reference.
■ Synonyms can be used to provide an abstraction layer to the user by presenting differ- ent names for database objects.
■ You can modify data through a synonym, but you cannot alter the underlying object.
■ To change a synonym, you must drop and recreate it.

■ Synonyms can reference objects in other databases or through linked servers.
■ Synonyms can be created to refer to database objects that do not yet exist.
*/

/* Case scenario 1
■ To remove the need for developers working with complex joins, you can present them with views and inline functions that hide the complexity of the joins. Because they will use stored procedures to update data, you do not need to ensure that the views are updatable.
■ You can change the names or de nitions of views and change table names without af- fecting the application if the application refers to synonyms. You will have to drop and recreate the synonym when the underlying table or view has a name change, and that will have to be done when the application is of ine.
■ You can use inline functions to provide viewlike objects that can be  ltered by param- eters. Stored procedures are not required because users can reference the inline func- tion in the FROM clause of a query.
*/

/* Case scenario 2
1. To  lter the data coming from the table, you can create a view or inline function that  l- ters the data appropriately, and recreate the synonym to reference the view or function.
2. To keep synonyms working even if column names of a table are changed, you can cre- ate a view that refers to the tables and recreate the synonym to refer to the view.
3. Synonyms cannot expose metadata. Therefore, when browsing a database in SSMS, users will not see column names and their data types under the synonym. In order to enable users to see the column data types of the underlying data tables, you must replace the synonym with a view.
*/

/*
1. Why is it recommended to specify the target column names in INSERT statements?
2. What is the difference between SELECT INTO and INSERT SELECT? Quick Check Answer
1. Also, you won’t be affected if the column order is rearranged due                                                                                 automatically are added.
2. SELECT INTO creates the target table and inserts into it the result of the query. INSERT SELECT inserts the result of the query into an already existing table

*/

/*

■ SQL Server provides two features to help you generate a sequence of keys: the IDEN- TITY column property and the sequence object.
■ The IDENTITY column property is de ned with a seed and an increment. When you insert a new row into the target table, you don’t specify a value for the IDENTITY col- umn; instead, SQL Server generates it for you automatically.
■ To get the newly generated identity value, you can query the functions SCOPE_IDENTITY, @@IDENTITY, and IDENT_CURRENT. The  rst returns the last identity value generated by your session and scope. The second returns the last identity value generated by your session. The third returns the last identity value generated in the input table.
■ The sequence object is an independent object in the database. It is not tied to a spe- ci c column in a speci c table.
■ The sequence object supports de ning the start value, increment value, minimum and maximum supported values, cycling, and caching.
■ You use the NEXT VALUE FOR function to request a new value from the sequence. You can use this function in INSERT and UPDATE statements, DEFAULT constraints, and as- signments to variables.
■ The sequence object circumvents many of the restrictions of the IDENTITY property.

*/

/*
1. What is the purpose of the ON clause in the MERGE statement?
2. What are the possible actions in the WHEN MATCHED clause?
3. How many WHEN MATCHED clauses can a single MERGE statement have?
Quick Check Answer
1. The ON clause determines whether a source row is matched by a target row, and whether a target row is matched by a source row. Based on the result of the predicate, the MERGE statement knows which WHEN clause to activate and as a result, which action to take against the target.
2. UPDATE and DELETE.
3. Two—one with an UPDATE action and one with a DELETE action.
*/