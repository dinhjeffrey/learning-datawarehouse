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