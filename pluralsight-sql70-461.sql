-- show list price compared to the average for that subcategory
select p.name,
	p.listprice - ap.averagelistprice as differencefromsubcategoryaverage
from production.product as p
inner join
(select productsubcategoryid,
	avg(listprice) as 'averagelistprice'
	from production.product
	group by ProductSubcategoryID) as ap
on ap.productsubcategoryid = p.productsubcategoryid;


-- territory with more then $20m in sales
select sum(soh.totaldue) as 'SalesAmount',
	st.name as 'SalesTerritory'
from sales.SalesOrderHeader as soh
	inner join sales.SalesTerritory as st
	on soh.TerritoryID = st.TerritoryID
	group by st.name
	having sum(soh.totaldue) > 20000000;

/*
with rollup: 
answers question what if we wanna see total for category, subcategory, in addition to product
ex: total for all, for each category, for each subcategory, and each product

with cube:
does it for all combination, respecting the order
ex: category, subcategory, product
category, subcategory
category, product
subcategory, product
category
subcategory
product

*/

select category,
	subcategory,
	product,
	sum(totaldue) as 'TotalSold'
from sales.vsalesbycategory
group by category,
	subcategory,
	product
with rollup
order by category,
	subcategory,
	product

/*
grouping set:
we want to have control when using with rollup or with cube
grouping set((category, subcategory), (category), (product))

how do we know if the null are part of the row or from with rollup, cube?
grouping and grouping_id

grouping:
1 - means being used for a total
0 - part of the row

less amount of columns? use grouping_id
grouping_id(category, subcategory, product)
ex.
1. product
2. subcategory
3. subcategory, product
4. category
5. category, product
6. category, subcategory
7. category, subcategory, product
*/

-- cte, it breaks down complex logic
with salesdata (totalsold, orderyear, territoryname)
as (
	select sum(soh.totaldue),
	year(soh.orderdate),
	st.name
	from sales.SalesOrderHeader as soh
	inner join sales.SalesTerritory as st
	on soh.TerritoryID = st.TerritoryID
	group by year(soh.orderdate),
		st.name
)

select * 
from salesdata

use AdventureWorks2012;

-- cte, it breaks down complex logic
with salesdata (totalsold, orderyear, territoryname)
as (
	select sum(soh.totaldue),
	year(soh.orderdate),
	st.name
	from sales.SalesOrderHeader as soh
	inner join sales.SalesTerritory as st
	on soh.TerritoryID = st.TerritoryID
	group by year(soh.orderdate),
		st.name
)

select * 
from salesdata
	pivot (sum(totalsold) -- not pivot
		for orderyear in ([2007], [2008], [2006], [2005])) as pvt; --pivots

/*
except and intersect
except: finds rows not in either tables
intersect: finds rows in both tables
*/

/* Ranking Functions
ROW_NUMBER
	- returns the row number
RANK
	- returns ranking based on ORDER BY statement
	- Ties skips to the next number
DENSE_RANK
	- returns ranking based on ORDER BY statement
	- Ties don't advance the next number
NTILE(x)
	- breaks rows into equal sections
	- x is the number of sections

*/

select name,
	listprice,
	row_number() over (order by listprice desc) as 'Row_Number',
	rank() over (order by listprice desc) as 'Rank',
	dense_rank() over (order by listprice desc) as 'Dense_Rank',
	ntile(4) over (order by listprice desc) as 'NTile'
from Production.Product
where ProductSubcategoryID = 1
order by listprice desc;

/*
fetch and offset
fetch: indicates number of rows to retrieve
offset: indicates number of rows to skip

*restrictions*
- TOP is not allowed
- ORDER BY is required 
*/

/* DISTINCT
removes duplicates
entire row must be a duplicate
will cause a sort of data - impacts performance
*/

/* NULL Functions
ISNULL
- two paramaters
	- returns the first paramter if it is not null
	- returns second paramter if it is null

COALESCE
- multiple parameters
	- returns the first parameter SQL find that is not null
- more flexible and easier to read
*/

-- only difference is coalesce allows for more than 1 paramter
select firstname,
	lastname,
	isnull(middlename, 'not available') as 'isnullmiddlename',
	coalesce(middlename, firstname, 'not available') as 'coalescemiddlename'
from person.Person