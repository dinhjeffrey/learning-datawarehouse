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

/* Date/Time Functions
GETDATE()
	- returns the current server date
GETUTCDATE()
	- returns the server date normalized to UTC
DATEPART()
	- returns a part of a date
	- related to DAY(), MONTH(), and YEAR()

DATEDIFF()
	- difference between two dates
DATEADD()
	- add time to a date
ISDATE()
	- determines if value is a date

DATEFROMPARTS()
	- builds a day from a provided year, day, month
TIMEFROMPARTS()
	- builds a time from a provided hour, minute, second
EOMONTH()
	- provides the last day of the month for the provided date
PARSE()
	- converts string to a date
*/

select max(soh.orderdate) as 'MostRecentOrderDate',
	year(max(soh.orderdate)) as 'MostRecentOrderYearYEARFunction',
	datepart(year, max(soh.orderdate)) as 'MostRecentOrderYearDatePart',
	c.lastname
from sales.SalesOrderHeader as soh
	inner join person.Person as c
		on soh.ContactId = c.ContactId
group by c.lastname;

select datediff(day, max(soh.orderdate), getdate()) as 'DaysSinceLastOrder'
	c.lastname
from sales.SalesOrderHeader as soh
	inner join person.Person as c
		on soh.ContactId = c.ContactId
group by c.lastname;

select eomonth(getdate()); -- last day of this month

/* String Functions
CHARINDEX()
- searches for one string inside another
PATINDEX()
- supports pattern searches inside of a string
LEFT() and RIGHT()
- Returns characters from left or right of a string
LTRIM() and RTRIM()
- removes string whitespace from a string
LEN()
- returns the length of a string 

CONCAT()
- concatenates a string
FORMAT()
- converts value to a string using .NET formatting
*/

select charindex('poop', 'i like to go pooping in the mornings')

select patindex('%poop%', 'i like to go pooping in the mornings')

select concat(name, ' costs ', listprice) as 'Display'
from Production.Product
where listprice > 0;

select name + ' costs ' + cast(listprice as nvarchar) as 'Display'
from Production.Product
where listprice > 0;

select name + ' costs ' + convert(nvarchar, listprice) as 'Display'
from Production.Product
where listprice > 0;

select try_parse('1/100/2012' as date) -- returns null instead of failing

/*
CONVERT(type, value, format)
	- accepts a formatting option
CAST(value AS type)



returns null if parse fails?
TRY_PARSE()
TRY_CONVERT()
*/

/*
CHOOSE()
- returns a list based on its location
- first paramter is index
- next paramters are the list

IIF()
- instant if
- three paramters:
	- boolean expression
	- return value if true
	- return value if false
*/

select choose(3, firstname, lastname, firstname + ' ' + lastname) as name
from person.person;

select iif(listprice > 0, 'Normal Product', 'Internal Component') as productinfo,
	name
from Production.Product;

/* Indexes
Clustered Index:
	- order in which the data in the table is stored
	- page number in a book
Nonclustered Index:
	- copy of data sorted for queries
	- index in the back of a book
		- contains a pointer back to the original content
*/

/* Join Algorithms
Merge Join
- Data is presorted
- Most efficient join

Loop Join (Nested Loops)
- One table is much smaller than the other
- smaller table is searched for values that match larger table

Hash Join
- Large tables and unsorted data
- Slowest type of join

*/

/* 
Dynamic Management Objects
Used to see what's going on behind the scenes
	- find out how sql server is using resources
	- identify problem queries
Views are treated like tables
Function accept parameters
	- parameters are often other database objects
*/

/* Index Dynamic Management Objects
sys.dm_db_index_usage_stats
	- determines whether indexes are (or aren't) being used
sys.dm_db_missing_index_details
	- determines what indexes SQL server thinks should be added 
sys.dm_db_index_physical_stats
	- determines how an index is using disk space
*/

/* Transaction Dynamic Management Objects
sys.dm_db_database_transactions
	- information about transactions in the database
sys.dm_db_session_transactions
	- information about transactions for session
sys.dm_tran_locks
	- information about data locked for transactions
*/

-- dynamic sql, use parameters to secure against attacks
declare @sql nvarchar(500) = 'select choose(3, firstname, lastname, firstname + '' '' + lastname) as name
from person.person where lastname = @LastName';

declare @parameterDefinitions nvarchar(500) = '@LastName nvarchar(50)';

execute sp_executesql @sql, @parameterDefinitions, @LastName = 'Harrison';

-- INSERT
insert into Production.ProductCategory
(name, rowguid, ModifiedDate)
values ('Light', NEWID(), GETDATE()),
		('L', NEWID(), GETDATE());

select * from Production.ProductCategory
where name in ('Light', 'L');

-- UPDATE is very dangerous, use with WHERE statement or it'll update entire table.
-- there are checks for DELETE but not UPDATE, be careful with UPDATE statement!
update production.Product
set listprice = ListPrice * 1.1,
	ModifiedDate = getdate()
where ProductSubcategoryID = 1;

select * from Production.product
order by modifieddate desc;

-- DELETE
select * from Production.ProductCategory;
delete from Production.ProductCategory
where ProductCategoryID > 4;

/* DELETE, TRUNCATE
avoid using TRUNCATE
TRUNCATE:
	- deletes all rows from a table
	- does not log operation
	- not available for tables serving as a parent for child tables
		- could not truncate Customers table if Orders had a foreign key relationship to Customers
*/

-- OUTPUT. Log changes
update production.Product
set listprice = ListPrice * 1.1
output inserted.name,
	deleted.ListPrice as 'old price',
	inserted.listprice as 'new price'
-- INTO Table
where ProductSubcategoryID = 1;

/* MERGE Concepts
Combine data from two tables
	- one table is source, other is target
Determine how to handle conflicts
	- Update existing data
	- Insert missing data

MERGE Components:

MERGE <Target>
	- where to place data
USING <Source>
	- where to get data from
ON 
	- the join to determine matches

MERGE Matching Options:

WHEN MATCHED THEN
	- Operation for existing data

WHEN NOT MATCHED [BY TARGET] THEN
	- Operation for missing data
	- Can have optional parameter applied to filter target rows
WHEN NOT MATCHED [BY SOURCE] THEN
	- Operation for missing data
	- Can have optional parameter applied to filter target rows

OUTPUT
	- Retrieve modified data
	- $action provides the action taken
		- insert
		- delete
*/

merge dbo.target as t -- Target table
using dbo.source as s -- Source table
	on t.employeeid = s.employeeid
when matched then -- Row exists in target, let's do update
	update set t.employeename = s.employeename
when not matched then -- Row doesn't exist in target, let's do insert
	insert values (s.employeeid, s.employeename)
output $action as 'Action',
	inserted.employeeid as 'NewEmployeeId',
	inserted.employeename as 'NewEmployeeName',
	deleted.employeeid as 'OldEmployeeId',
	deleted.employeename as 'OldEmployeeName' 


/*
Transactions:
Allows us to control whether everything succeeds,
or everything is going to get rolled back.
SQL transactions meet the ACID test

ACID:

Atomic
	- everything succeeds or fails as a single unit
Consistent
	- when the operation is complete, everything is left in a safe state
Isolated
	- No other operation can impact my operation
Durable
	- When the operation is completed, changes are safe
*/

/* Implicit and Automatic Transactions
Automatic Transactions
	- Automatically commits after each statement
Implicit Transactions
	- Must manually commit

Manual Transactions

BEGIN TRANSACTION (or TRAN)
	- starts a transaction
COMMIT TRANSACTION (or TRAN)
	- writes all changes back to database
ROLLBACK TRANSACTION (or TRAN)
	- reverses all operations 
*/

begin tran;

select firstname, lastname
from person.person;

update person.person
set lastname = 'Nguyen'

rollback tran;

/*
someone wants to work with data I'm current working with?
They are not allowed to touch that. implemented through Concurrency and locks

Concurrency - process of managing data access
Locks:

- Shared
	- read lock
- Exclusive
	- write lock
	- prevents other users from accessing data
- Update
	- not exclusive to update statements
	- hybrid lock
		- starts as a shared lock, then elevates to exclusive
- Intent
	- ensures containers are not modified when accessing data
		- Intent lock ensures table isnt dropped when executing a query

Lock levels
	- Row locks
	- Page locks (8k block of data in which data is stored)
	- Table locks

*/

/*
Lost updates
Dirty reads
Non-repeatable reads
Phantom reads

what is a repeatable read?
	- locks modified data until end of transaction
	- locks read data until end of transaction
	- goal is to not allow new data while working with transaction

Isolation Levels
isolation levels control how data is locked
SET TRANSACTION ISOLATION LEVEL <option>

SET TRANSACTION ISOLATION LEVEL
READ UNCOMMITTED; -- does not honor locks. Lost updates

SET TRANSACTION ISOLATION LEVEL
READ COMMITTED; -- honor locks. Dirty reads

SET TRANSACTION ISOLATION LEVEL
REPEATABLE READ; -- locks transaction, so no new data allowed while working with it

SET TRANSACTION ISOLATION LEVEL
SERIALIZABLE; -- prevent phantom read. can lock entire table if there are no indexes, so be careful using SERIALIZABLE.

*/

/*
SERIALIZABLE
- Locks modified data until end of transaction
- Locks read data until end of SELECT statement
- No other transaction can insert data into the range specified by any WHERE clause(predicate)

*/

/*
Snapshot
- uses versioning
	- versions are maintained in tempdb
	- each person can have their own version without affecting another's

*/

alter database AdventureWorks2012
set allow_snapshot_isolation on;

/*
MAIN 3: CONCURRENCY, TRANSACTION, LOCK
*/

/* Error Handling
2 main ways:
@@ERROR variable
	-- not preferred way
	-- requires checking variable after every operation

TRY/CATCH
	-- "do these steps and get back to me when something goes wrong"
TRY/CATCH SYNTAX
BEGIN TRY
	-- perform tasks
END TRY
BEGIN CATCH
	-- error handling
END CATCH


*/

BEGIN TRY

	BEGIN TRANSACTION;

	UPDATE production.productcategory
	set name = 'widgets'
	where ProductCategoryid = 1;

	delete from production.ProductSubcategory
	where ProductSubcategoryid = 1;

	COMMIT TRAN;
END TRY
-- nothing allowed here
BEGIN CATCH

	ROLLBACK TRAN;

	PRINT 'An Error Occurred Oi choi oi';

END CATCH

/* Error Informational Functions
ERROR_NUMBER()

ERROR_PRODCEDURE()

ERROR_LINE()

ERROR_MESSAGE()

ERROR_SEVERITY() & ERROR_STATE()

*/

/* Raising errors
Raise errors when you detect problems
Two methods:
	- RAISERROR function
	- THROW keyword

Severity and State
Severity:
	- Provide info about the type of problem
	- Number 10 is informational
	- Number 11-16 are errors fixed by the user
	- most common is Number 16
State:
	- Provide additional info on the error
	- most common to use Number 1
*/

RAISERROR('This is a demo message', 16, 1);

/*
Difference with RAISERROR and THROW is THROW can be
used with TRY/CATCH and makes it an error SSMS can log.
Also severity for THROW is always 16
We can re-THROW while RAISEERROR cannot
*/
THROW 5000, 'This is a demo error', 1;

/*
create database DemoDataBase;
use DemoDatabase;
GO
*/

create table orders
(
	orderid int not null,
	orderdate date not null,
	shipdate date null
);

select * from orders;

/* Altering Tables
Adding a column
	- ADD
Changing a column type
	- ALTER COLUMN
Removing a column
	- DROP
*/

/* Validation options
- use constraints over triggers because triggers are slower
Constraints
	- default values
	- primary key and unique columns
	- foreign key
	- custom code
	- identity column
		- not really a constraint

Triggers
	- complex code
	- compare valuesto other table or rows
*/

/* Implementing Constraints

*/

-- Existing Table
alter table dbo.orders
add constraint DF_OrderDate_CurrentDate DEFAULT GETDATE() for OrderDate; -- DF for Default

-- New Table
create table dbo.customers
	(
		OrderDate date not null CONSTRAINT DF_OrderDate_CurrentDate DEFAULT GETDATE()
	)

/* Identity columns
IDENTITY(starter, increment)

Check constraints
- confirm values are in an acceptable range
*/

-- check constraint
-- existing table
alter table dbo.orders
add constraint ck_orders_ShipDateIsNullOrAfterOrderDate
	check (shipdate is null or shipdate >= orderdate);

-- new table
create table dbo.orders
	(
		constraint ck_orders_ShipDateIsNullOrAfterOrderDate
			check(shipdate is null or shipdate >= orderdate)
	)

/*
Unique constraints
- enforces unique values
- one null value allowed
- creates an index
- can have multiple unique constraints per table, only 1 primary key per table
*/


-- existing table
alter table dbo.customers
add constraint AK_Customers_EmailAddress unique (emailaddress);


-- new table
create table dbo.customers
	(
		emailaddress varchar(100) constraint AK_Customers_EmailAddress UNIQUE -- AK = alternate key, convention for unique
	)

/* Primary Key

*/

-- existing table
alter table dbo.customers
add constraint PK_Customers_CustomerID PRIMARY KEY (CustomerID);

-- new table
create table dbo.customers
	(
		CustomerID int not null identity(1,1)
		CONSTRAINT PK_Customers_CustomerID PRIMARY KEY (CustomerID)
	)

/* Foreign Key Cascade Options
What happens if "parent" value is modified?

Options
- SET NULL
	- sets local value to NULL
- SET DEFAULT
	- sets local value to default or NULL
- CASCADE
	- deletes local rows
- NO ACTION
	- action will be denied and return an error
*/

/* Foreign Key Cascade Demo

*/

-- existing tables
alter table dbo.orders
add constraint FK_Orders_Customers_CustomerID
	foreign key (customerid) references dbo.customers (customerid);


-- new tables
create table dbo.customers
(
	customerid int not null(1,1),
	CONSTRAINT PK_Customers_CustomerID PRIMARY KEY (customerid)
)

Create table dbo.orders
(
	orderid int not null identity(1,1),
	customerid int not null,
	CONSTRAINT PK_orders_orderid PRIMARY KEY (orderid),
	constraint FK_Orders_Customers_CustomerID
		FOREIGN KEY (customerid) references dbo.customers (customerID)
)


/*
Triggers
- Triggers are part of the current transaction
- triggers are hidden

2 types:
Instead-Of Triggers:
- captures the intended operation
- common uses
	- allow modification on views
	- mark an item as inactive instead of deleting it
After Triggers:
- executes after the operation completes successfully
- still part of the same transaction
	- can rollback the transaction
- common uses 
	- log modification
	- update tables

Trigger Logic
Special Tables
- INSERTED
	- provides new data for INSERT and UPDATE
- DELETED
	- provides old data for INSERT and UPDATE
Row Count
- consider using SET NOCOUNT ON
	- having duplicate messages can confuse users

*/

-- use AdventureWorks2012;

/* Trigger
Goals:
when somebody DELETE, set IsActive = 0
somebody change name, record in CustomersArchive
*/
create table dbo.customers
(
	customerid int identity(1,1) not null,
	name varchar(50) not null,
	isactive bit not null constraint df_customers_isactive default(1),
	constraint pk_customers_customerid primary key (customerid)
);
go

create table dbo.customersarchive
(
	customerid int not null,
	oldname varchar(50) not null,
	newname varchar(50) not null
);
go

create trigger I_D_Customers_MarkCustomerAsInactive -- D for deleted
on dbo.customers
instead of delete
as
begin
	set nocount on; -- suppress the number of rows affected

	update dbo.customers
	set isactive = 0
	from dbo.customers as c
		inner join deleted as d on c.customerid = d.customerid
end;


insert into dbo.customers(name)
values ('chris');

delete from dbo.customers
where customerid = 1;

select * from dbo.customers;

-- Archive customer name after update
create trigger A_U_Customers_ArchiveNameChanges
on dbo.customers
after update
as 
begin
	set nocount on; -- suppress the number of rows affected
	
	insert into dbo.customersarchive(customerid, oldname, newname)
	select i.customerid,
		d.name, -- old name
		i.name -- new name
	from deleted as d
		inner join inserted as i
			on d.customerid = i.customerid
			and d.name != i.name; -- ensure the name has changed
end;

insert into dbo.customers(name)
values('brian');

update dbo.customers
set name = 'Dave'
where name = 'brian';

select * from dbo.customersarchive;

/* Views
Index views (or Materialized view) - all data written to disk

ENCRYPTION
- encrypts the definition, prevents all users from accessing the script
- issues 
	- nobody can access it
	- easily cracked

SCHEMABINDING
- underlying table cannot be modified in a way that would impact the view

VIEW_METADATA
- enables external APIs to browse metadata

CHECK OPTION
- specified at the end
- prevents modifications that would cause data to leave the view

*/

/*
Stored Procedure Options

ENCRYPTION
- encrypts the definition, preventing all users from accessing the script
- issues 
	- nobody can access it
	- easily cracked

EXECUTE AS <option>
- execute the stored procedure as a different user
- advanced option

RECOMPILE
- stored procedure recompiles after every execution
- advanced option



Stored Procedure Parameters
@Name
Datatype
Options
- OUT or OUTPUT
	- return a value
- Default value
	- set the parameter equal to the default value

- Return values
	- indicate a status code

*/


create procedure production.up_category_insert -- UP for user stored procedure
	@name varchar(50)
as
insert into production.ProductCategory(name)
values(@name);

select scope_identity(); -- uses most recently created identity

declare @name varchar(50) = 'Created from stored procedure';
exec production.up_category_insert @name;

select * from Production.ProductCategory
where ProductCategoryID = 8;

/*
Scalar Function
*/

create function sales.uf_MostRecentCustomerOrderDate(@CustomerID int)
	returns datetime
as
BEGIN;
	DECLARE @MostRecentOrderDate datetime;

	select @MostRecentOrderDate = MAX(orderdate)
	from sales.SalesOrderHeader
	where customerid = @customerid;

	return @MostRecentOrderDate;
END; 

/*
Inline Table Value Functions

Single SELECT statement to return values
	- similar to a view that accepts paramters

*/

create function sales.uf_CustomerOrderDate(@CustomerID int)
	returns table
as
return
	select orderdate
	from sales.SalesOrderHeader
	where customerid = @customerid;

/*
Multi-Statement Table Valued Function

- returns a table but can use complex logic
*/

/* Apply operators

"Join" tables to functions
	- pass column as parameter into function

CROSS APPLY
	- similar to inner join
OUTER APPLY
	- similar to outer join

*/

select c.customerid,
	cod.orderdate
	from sales.customer as c
	cross apply sales.uf_CustomerOrderDate(c.customerid) as cod;

