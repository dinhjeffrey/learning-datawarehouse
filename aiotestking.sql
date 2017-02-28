/*
You need to ensure that users can update only the phone numbers and email addresses by using this view. What should you do?

Create an INSTEAD OF UPDATE trigger on the view
*/

/*
You need to create a computed column that returns the sum total of the ItemsInStore and ItemsInWarehouse values for each row. The new column is expected to be queried heavily, and you need to be able to index the column.

ADD TotalItems as ItemsInStore + ItemsInWarehouse PERSISTED
*/


-- You need to create an audit record only when the MobileNumber or HomeNumber column is updated.
create trigger TrgPhoneNumberChange
on customers for update
as 
if update(HomeNumber) or update(MobileNumber)

-- You need to ensure that when multiple records are inserted in the Transactions table, only the records that have
-- a valid AccountNumber in the SavingAccounts or LoanAccounts are inserted.
create trigger TrgValidateAccountNumber
on Transactions
instead of inserted
as
begin
insert into Transactions
select transactionid, accountnumber, amount, transactiondate from inserted
where accountnumber in
(select accountnumber from LoanAccounts
union select accountnumber from savingaccounts)
end

/*
-- You create a view:
-- joins 8 tables that contain up to 500,000 records each
-- performs aggregations on 5 fields.
-- view is used in several reports. you need to improve the performance of the reports

convert the view into an <b>index view</b>.
*/

-- You need to ensure that the customerid column in the orders table contains only values that exists in the customerid column of the customer table
alter table orders
add constraint FX_Orders_CustomerID FOREIGN KEY (customerid) REFERENCES
customer (customerid)

select SalesTerritoryID,
	ProductID,
	AVG(UnitPrice) as averageunitprice,
	MAX(OrderQty) as maxorderqty,
	MAX(DiscountAmount) as maxdiscountamount
FROM Sales.Details
group by SalesTerritoryID, ProductID
order by SalesTerritoryID desc, ProductID desc
;

select c.lastname, max(o.orderdate) as MostRecentOrderDate
from customers as c
inner join orders as o
on c.customerid = o.customerid
group by c.lastname
order by orderdate desc;

-- need to declare a variable of the XML type named XML1. The solution must
-- ensure that the XML1 is validated by using Sales.InvoicedSchema
@XML1 XML(Sales.InvoicedSchema)

select pc.catid, pc.catname, pc.ProductID,
pc.prodname, pc.unitprice,
rank() over (partition by pc.unitprice order by pc.unitprice desc) as PriceRank
from sales.productcatalog as pc
order by pc.unitprice desc;

create procedure usp_Customers @Count into
as
select top(@Count) c.lastname
from customers as c
order by lastname asc;

-- write results to a disk
-- "Persisted" means "stored physically" in this context. It means that the computed value is computed once on insert (and on updates) and stored on disc, so it does not have to be computed again on every select
create table sales.orderdetails (X
ListPrice money not null,
Quantity int not null,
LineItemTotal as (ListPrice * Quantity) PERSISTED)

-- the view must prevent the underlying structure of the customer table form being changed
create view 'uv_CustomerFullNameto'
with schemabinding
as
select c.firstname, c.lastname
from sales.customers as c

select  orderid, sum(extendedamount) as TotalSales
from sales.details
group by orderid
order by orderid

-- total sales made by sales people, year, city, and country
-- sub totals only at the city level and country level
-- a grand total of the sales amount
select salesperson.name, country, city,
datepart(yyyy, saledate) as year, sum(amount) as total
from sale inner join salesperson
on sales.salespersonid = salesperson.salespersonid
group by grouping sets((salesperson.name, country, city, datepart(yyyy, saledate), (country, city), ()))

-- you need to store prices with a fixed precision and a scale of six digits
-- NUMERIC gives afixed precision and scale.

-- has to be unique within the Employee table
-- exists only within the Employee table
-- UNIQUE CONSTRAINT

-- modify the Products table
-- remove all duplicates of the Products table based on the ProductName column
-- retain only the newest Products row
with CTEDupRecords
as
(
select max(createdDateTime) as CreatedDateTime, ProductName
from Products
group by ProductName
having count(*) > 1
)
delete p 
from products p
inner join CTEDupRecords cte on
cte.productname = p.ProductName
and cte.createdDateTime > p.CreatedDateTime;

-- ensure that callers that do not have permissions can execute the stored procedure
EXECUTE AS OWNER;





