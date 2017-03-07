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

-- Status info must be logged to a status table
-- If the status table does not exist at the beginning of the batch, it must be created.
-- ans: stored procedure

-- partition number must:
-- always start with 1
-- start again from 1 after it reaches 100
CREATE SEQUENCE CustomerSequence AS int
START WITH 1
INCREMENT BY 1
MINVALUE 1
MAXVALUE 100
CYCLE
UPDATE Customers SET PartitionNumber = NEXT VALUE FOR CustomerSequence
DROP SEQUENCE CustomerSequence

-- Id is the Primary Key
-- You need to append the "This is in a draft stage" string to the summary column
-- of the recent 10 entries based on the values in EntryDateTime
UPDATE BlogEntry
SET Summary.WRITE(N'This is in a draft stage', NULL, 0) FROM (
SELECT TOP(10) Id FROM BlogEntry ORDER BY EntryDateTime DESC) as s
where BlogEntry.Id = s.ID

-- when DeleteJobCandidate encounters error, the execution of the stored procedure reports the error number
DECLARE @ErrorVar INT;
DECLARE @RowCountVar INT;
EXEC DeleteJobCandidate
SELECT @ErrorVar = @@ERROR, @RowCountVar = @@ROWCOUNT;
IF (@ErrorVar <> 0)
PRINT N'Error = ' + CAST(@@ErrorVar AS NVARCHAR(8)) + 
N', Rows Deleted = ' + CAST(@@RowCountVar AS NVARCHAR(8))
GO

-- when DELETE statement succeeds, the modification is retained
-- even if insert into the Audit.Log table fails
IF (XACT_STATE()) = 1

-- Territory, Year and Profit.
-- create report that displays the profit made by each territory for each year and its preceding year
SELECT Territory, Year, Profit
LAG(Profit, 1, 0) OVER(PARTITION BY Territory ORDER BY Year) AS NextProfit
FROM Profits

-- send data to an NVARCHAR(MAX) variable named @var
-- success of a cast to a decimal (36, 9)
SELECT
IIF(TRY_PARSE(@var AS decimal(36,9)) IS NULL, 'True', 'False')
AS BadCast

-- FILESTREAM-enabled database
-- will update multiple tables within a transaction
-- if stored procedure raises a runtime error, the entire transaction is terminated and rolled back
SET XACT_ABORT ON

-- sum total
create table Inventory
(ItemID int not null primary key,
ItemsInStore int not null,
ItemsInWarehouse int not null)

alter table inventory
add TotalItems as ItemsInStore + ItemsInWarehouse


-- need to improve performance of view by persisting data to disk
-- **create a clustered index on the view

-- you need to store the departure and arrival dates and times of flights
-- along with timezone info
-- **DATETIMEOFFSET

-- created a stored procedure
-- supply stored procedure with multiple event names and their dates as parameters
-- **Use a user-defined table type.

select orderid, sum(extendedamount) as TotalSales
from Sales.Details
group by orderid
order by orderid;

-- must include customer who have not placed any orders
select customername, orderdate
from customers
left outer join orders
on customers.customerid = orders.customerid;

-- store procedure, if it raises a run-time error, entire transaction is terminated and rolled back
set xact_abort on

-- NCI_OrderDetail_CustomerID non-clustered index is fragmented
-- need to reduce fragmentation
-- need to achieve this goal without taking the index offline
alter index NCI_OrderDetail_CustomerID on OrderDetail.CustomerID REORGANIZE

-- future mods to table definition will not affect applications' ability to access data
-- new object can accomodate data retrieval and data modification
-- minimum amount of changes to the existing application
VIEWS

-- batch process
-- return results on supplied parameteres
-- enables the returned result set to perform a join with a table
Table-valued user-defined function

-- create a stored procedure
-- accepts a single input parameter for customerID
-- returns a single integer to the calling application
DECLARE @CustomerRatingByCustomer INT
EXECUTE dbo.GetCustomerRating @CustomerID = 1745,
@CustomerRating = @CustomerRatingByCustomer OUPUT

Create Procedure dbo.GetCustomerRating @Customer INT, @CustomerRating INT OUTPUT
AS
SET NOCOUNT ON SELECT @CustomerRating = CustomerOrders/CustomerValue
FROM Customers WHERE CustomerID = @CustomerID
return
GO
