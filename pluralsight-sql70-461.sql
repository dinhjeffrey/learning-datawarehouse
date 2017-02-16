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
