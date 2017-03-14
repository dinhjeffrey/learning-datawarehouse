/**===================================================
Modify data (20-25%)
===================================================**/

-- * Working with functions
	-- * Understand deterministic, non-deterministic functions; scalar and table values; apply built-in
	-- * scalar functions; create and alter user-defined functions (UDFs)
-- Scalar Functions
-- takes one input value, a ProductID, and returns a single data value,
-- the aggregated quantity of the specified product in inventory
if object_id (N'dbo.ufnGetInventoryStock', N'FN') is not null
	drop function ufnGetInventoryStock;
go
create function dbo.ufnGetInventoryStock(@ProductID int)
returns int
as
-- returns the stock level for the product
begin
	declare @ret int;
	select @ret = sum(p.Quantity)
	from Production.ProductInventory p
	where p.ProductID = @ProductID
		and p.LocationID = '6';
	if (@ret is null)
		set @ret = 0;
	return @ret;
end;
go