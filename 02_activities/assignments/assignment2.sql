/* ASSIGNMENT 2 */
/* SECTION 2 */

-- COALESCE
/* 1. Our favourite manager wants a detailed long list of products, but is afraid of tables! 
We tell them, no problem! We can produce a list with all of the appropriate details. 

Using the following syntax you create our super cool and not at all needy manager a list:

SELECT 
product_name || ', ' || product_size|| ' (' || product_qty_type || ')'
FROM product

But wait! The product table has some bad data (a few NULL values). 
Find the NULLs and then using COALESCE, replace the NULL with a 
blank for the first problem, and 'unit' for the second problem. 

HINT: keep the syntax the same, but edited the correct components with the string. 
The `||` values concatenate the columns into strings. 
Edit the appropriate columns -- you're making two edits -- and the NULL rows will be fixed. 
All the other rows will remain the same.) */

--check which columns are null
SELECT *
FROM product
WHERE product_name is NULL 
	or product_size is NULL 
	or product_qty_type is NULL;

--concatenate the list
SELECT product_id,product_size, product_qty_type,
product_name || ', ' || coalesce(product_size, '') || ' (' || coalesce(product_qty_type, 'unit') || ')'
FROM product;


--Windowed Functions
/* 1. Write a query that selects from the customer_purchases table and numbers each customer’s  
visits to the farmer’s market (labeling each market date with a different number). 
Each customer’s first visit is labeled 1, second visit is labeled 2, etc. 

You can either display all rows in the customer_purchases table, with the counter changing on
each new market date for each customer, or select only the unique market dates per customer 
(without purchase details) and number those visits. 
HINT: One of these approaches uses ROW_NUMBER() and one uses DENSE_RANK(). */
SELECT *,
row_number() OVER (PARTITION BY customer_id ORDER by market_date) 
FROM customer_purchases;


/* 2. Reverse the numbering of the query from a part so each customer’s most recent visit is labeled 1, 
then write another query that uses this one as a subquery (or temp table) and filters the results to 
only the customer’s most recent visit. */
WITH sub1 as(
	SELECT *,
	row_number() OVER (PARTITION BY customer_id  ORDER by market_date DESC, transaction_time DESC) as visitnum
	FROM customer_purchases
	)
SELECT * 
	FROM sub1 
	WHERE visitnum=1;

/* 3. Using a COUNT() window function, include a value along with each row of the 
customer_purchases table that indicates how many different times that customer has purchased that product_id. */
SELECT *,
	COUNT() OVER (PARTITION BY customer_id, product_id) as nbought
	FROM customer_purchases;


-- String manipulations
/* 1. Some product names in the product table have descriptions like "Jar" or "Organic". 
These are separated from the product name with a hyphen. 
Create a column using SUBSTR (and a couple of other commands) that captures these, but is otherwise NULL. 
Remove any trailing or leading whitespaces. Don't just use a case statement for each product! 

| product_name               | description |
|----------------------------|-------------|
| Habanero Peppers - Organic | Organic     |

Hint: you might need to use INSTR(product_name,'-') to find the hyphens. INSTR will help split the column. */
	
SELECT *
,CASE 
	WHEN rtrim(SUBSTR(product_name, INSTR(product_name,'-')+2))= 'Jar' THEN 'Jar'
	WHEN rtrim(SUBSTR(product_name, INSTR(product_name,'-')+2)) = 'Organic' THEN 'Organic'
	WHEN rtrim(SUBSTR(product_name, INSTR(product_name,'-')+2)) not in ('Jar', 'Organic') then NULL 
END	AS jar_organic
FROM product;

/* 2. Filter the query to show any product_size value that contain a number with REGEXP. */
SELECT *
,CASE 
	WHEN rtrim(SUBSTR(product_name, INSTR(product_name,'-')+2))= 'Jar' THEN 'Jar'
	WHEN rtrim(SUBSTR(product_name, INSTR(product_name,'-')+2)) = 'Organic' THEN 'Organic'
	WHEN rtrim(SUBSTR(product_name, INSTR(product_name,'-')+2)) not in ('Jar', 'Organic') then NULL 
END	AS jar_organic
FROM product
WHERE product_size REGEXP '[0-9]';


-- UNION
/* 1. Using a UNION, write a query that displays the market dates with the highest and lowest total sales.

HINT: There are a possibly a few ways to do this query, but if you're struggling, try the following: 
1) Create a CTE/Temp Table to find sales values grouped dates; 
2) Create another CTE/Temp table with a rank windowed function on the previous query to create 
"best day" and "worst day"; 
3) Query the second temp table twice, once for the best day, once for the worst day, 
with a UNION binding them. */

DROP TABLE IF EXISTS temp.sub1; 
--temp table of daily sales by market date
CREATE TEMP TABLE IF NOT EXISTS temp.sub1 AS
	SELECT *
	,sum(cost_to_customer_per_qty*quantity) as dailysale
	FROM customer_purchases
	GROUP BY market_date;

DROP TABLE IF EXISTS temp.sub2;
--temp table of highest sales ranked first and lowest sales last
CREATE TEMP TABLE IF NOT EXISTS temp.sub2 AS
	SELECT  *
	, dense_rank() OVER(ORDER BY dailysale DESC) as sale_rank
	FROM sub1
	;

--union of best and worst day of sales
SELECT *, "best day" as sale_rank_label 
	FROM sub2
	WHERE sale_rank= 1
UNION
SELECT * , "worst day" as sale_rank_label
	FROM sub2
	WHERE sale_rank = (SELECT MAX(sale_rank) FROM sub2);

	
/* SECTION 3 */

-- Cross Join
/*1. Suppose every vendor in the `vendor_inventory` table had 5 of each of their products to sell to **every** 
customer on record. How much money would each vendor make per product? 
Show this by vendor_name and product name, rather than using the IDs.

HINT: Be sure you select only relevant columns and rows. 
Remember, CROSS JOIN will explode your table rows, so CROSS JOIN should likely be a subquery. 
Think a bit about the row counts: how many distinct vendors, product names are there (x)?
How many customers are there (y). 
Before your final group by you should have the product of those two queries (x*y).  */

--1) Get all products and prices per vendor (N= 8 rows)
DROP TABLE IF EXISTS temp.VI_vendors;
CREATE TEMP TABLE IF NOT EXISTS temp.VI_vendors AS
	SELECT DISTINCT vi.vendor_id, vi.product_id, vi.original_price
		,v.vendor_name
		,p.product_name
	FROM vendor_inventory vi
	INNER JOIN vendor v ON vi.vendor_id= v.vendor_id
	INNER JOIN product p ON vi.product_id= p.product_id
	;

--2) Get unique customers (regardless of whether they've bought from vendor before)
DROP TABLE IF EXISTS temp.dist_customers;
CREATE TEMP TABLE IF NOT EXISTS temp.dist_customers AS
	SELECT DISTINCT customer_id
	FROM customer; 

--3) Perform cross join. N= 208 rows from 26 customers * 8 vendor-products 
DROP TABLE IF EXISTS temp.prod26c;
CREATE TEMP TABLE IF NOT EXISTS temp.prod26c AS
SELECT *
FROM temp.VI_vendors 
CROSS JOIN temp.dist_customers;

--4) Get total sums per vendor-product
SELECT *, sum(original_price) as expected_total_sales
	FROM temp.prod26c 
	GROUP BY vendor_id, product_id;


-- INSERT
/*1.  Create a new table "product_units". 
This table will contain only products where the `product_qty_type = 'unit'`. 
It should use all of the columns from the product table, as well as a new column for the `CURRENT_TIMESTAMP`.  
Name the timestamp column `snapshot_timestamp`. */
DROP TABLE IF EXISTS product_units;
CREATE TABLE product_units AS
	SELECT *, 
	CURRENT_TIMESTAMP as snapshot_timestamp
	FROM product
	WHERE product_qty_type = 'unit'
	; 


/*2. Using `INSERT`, add a new row to the product_units table (with an updated timestamp). 
This can be any product you desire (e.g. add another record for Apple Pie). */

INSERT INTO product_units
VALUES('7','Apple Pie','10"','3','unit',CURRENT_TIMESTAMP);

--Check if inserted correctly
SELECT * FROM product_units;

-- DELETE
/* 1. Delete the older record for the whatever product you added. 

HINT: If you don't specify a WHERE clause, you are going to have a bad time.*/
WITH PU as(
	SELECT *
		,ROW_NUMBER() OVER (PARTITION BY product_id ORDER BY snapshot_timestamp DESC) AS dupe_flag
	FROM product_units
	)

DELETE FROM product_units
	WHERE (product_id, snapshot_timestamp) IN (
		SELECT product_id, snapshot_timestamp
		FROM PU
		WHERE dupe_flag= 2
		)
;

--Check final table		
SELECT * FROM product_units ORDER by product_id;


-- UPDATE
/* 1.We want to add the current_quantity to the product_units table. 
First, add a new column, current_quantity to the table using the following syntax.

ALTER TABLE product_units
ADD current_quantity INT;

Then, using UPDATE, change the current_quantity equal to the last quantity value from the vendor_inventory details.

HINT: This one is pretty hard. 
First, determine how to get the "last" quantity per product. 
Second, coalesce null values to 0 (if you don't have null values, figure out how to rearrange your query so you do.) 
Third, SET current_quantity = (...your select statement...), remembering that WHERE can only accommodate one column. 
Finally, make sure you have a WHERE statement to update the right row, 
	you'll need to use product_units.product_id to refer to the correct row within the product_units table. 
When you have all of these components, you can run the update statement. */

--1) Create null column current_quantity
ALTER TABLE product_units
ADD current_quantity INT;

--2) Get the latest quantity from vendor_inventory based on market_date
DROP TABLE IF EXISTS TEMP.VI;
CREATE TEMP TABLE TEMP.VI AS
    WITH VI AS (
        SELECT *, 
               ROW_NUMBER() OVER (PARTITION BY product_id ORDER BY market_date DESC) AS latest
        FROM vendor_inventory
    )
    SELECT *
    FROM VI
    WHERE latest = 1;
	
SELECT * from temp.VI;
--only 8 products here vs 14 total so there will be some products without current_quantity 

UPDATE product_units
SET current_quantity = 
	coalesce(
		(SELECT quantity
		FROM temp.vi
		WHERE product_units.product_id= vi.product_id
		)
		,0)
	;

SELECT * from product_units;