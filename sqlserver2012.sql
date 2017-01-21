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
