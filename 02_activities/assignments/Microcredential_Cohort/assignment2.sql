/* ASSIGNMENT 2 */
--Please write responses between the QUERY # and END QUERY blocks
/* SECTION 2 */

-- COALESCE
/* 1. Our favourite manager wants a detailed long list of products, but is afraid of tables! 
We tell them, no problem! We can produce a list with all of the appropriate details. 

Using the following syntax you create our super cool and not at all needy manager a list:

SELECT 
product_name || ', ' || product_size|| ' (' || product_qty_type || ')'
FROM product


But wait! The product table has some bad data (a few NULL values). 
Find the NULLs and then using COALESCE, replace the NULL with a blank for the first column with
nulls, and 'unit' for the second column with nulls. 

**HINT**: keep the syntax the same, but edited the correct components with the string. 
The `||` values concatenate the columns into strings. 
Edit the appropriate columns -- you're making two edits -- and the NULL rows will be fixed. 
All the other rows will remain the same. */
--QUERY 1

SELECT *
FROM product
WHERE product_size IS NULL
   OR product_qty_type IS NULL;

SELECT 
  product_name || ', ' || COALESCE(product_size, '') || ' (' || COALESCE(product_qty_type, 'unit') || ')'
FROM product;

--END QUERY


--Windowed Functions
/* 1. Write a query that selects from the customer_purchases table and numbers each customer’s  
visits to the farmer’s market (labeling each market date with a different number). 
Each customer’s first visit is labeled 1, second visit is labeled 2, etc. 

You can either display all rows in the customer_purchases table, with the counter changing on
each new market date for each customer, or select only the unique market dates per customer 
(without purchase details) and number those visits. 
HINT: One of these approaches uses ROW_NUMBER() and one uses DENSE_RANK(). 
Filter the visits to dates before April 29, 2022. */
--QUERY 2

WITH customer_visits AS (
  SELECT DISTINCT customer_id, market_date
    FROM customer_purchases
  	WHERE market_date < '2022-04-29'
               )
SELECT
  customer_id,
  market_date,
  ROW_NUMBER() OVER 
    (
    PARTITION BY customer_id
    ORDER BY market_date
	) 
	AS customer_visit_number
FROM customer_visits
ORDER BY customer_id, market_date;

--END QUERY


/* 2. Reverse the numbering of the query so each customer’s most recent visit is labeled 1, 
then write another query that uses this one as a subquery (or temp table) and filters the results to 
only the customer’s most recent visit.
HINT: Do not use the previous visit dates filter. */
--QUERY 3

SELECT *
FROM (
  SELECT
    c_p.customer_id, 
	c_p.market_date,
    DENSE_RANK() OVER 
	(
      PARTITION BY c_p.customer_id
      ORDER BY c_p.market_date DESC
    ) 
	AS visit_number_reverse
    FROM customer_purchases AS c_p
    ) AS ranked
WHERE ranked.visit_number_reverse = 1
GROUP BY ranked.customer_id
ORDER BY ranked.customer_id, ranked.market_date DESC;

--END QUERY


/* 3. Using a COUNT() window function, include a value along with each row of the 
customer_purchases table that indicates how many different times that customer has purchased that product_id. 

You can make this a running count by including an ORDER BY in the window function if desired.
Filter the visits to dates before April 29, 2022. */
--QUERY 4

SELECT
  c_p.*,
  COUNT(*) OVER (
    PARTITION BY c_p.customer_id, c_p.product_id
  ) AS times_purchased
FROM customer_purchases AS c_p
WHERE c_p.market_date < '2022-04-29'
ORDER BY c_p.customer_id, c_p.product_id, c_p.market_date;

--END QUERY


-- String manipulations
/* 1. Some product names in the product table have descriptions like "Jar" or "Organic". 
These are separated from the product name with a hyphen. 
Create a column using SUBSTR (and a couple of other commands) that captures these, but is otherwise NULL. 
Remove any trailing or leading whitespaces. Don't just use a case statement for each product! 

| product_name               | description |
|----------------------------|-------------|
| Habanero Peppers - Organic | Organic     |

Hint: you might need to use INSTR(product_name,'-') to find the hyphens. INSTR will help split the column. */
--QUERY 5

SELECT
  p.product_name,
  NULLIF(
    TRIM(
      SUBSTR(
        p.product_name,
        INSTR(p.product_name, '-') + 1
      )
    ),
    ''
  ) AS description
FROM product AS p;

--END QUERY


/* 2. Filter the query to show any product_size value that contain a number with REGEXP. */
--QUERY 6

SELECT *
FROM product
WHERE product_size REGEXP '[0-9]';

--END QUERY


-- UNION
/* 1. Using a UNION, write a query that displays the market dates with the highest and lowest total sales.

HINT: There are a possibly a few ways to do this query, but if you're struggling, try the following: 
1) Create a CTE/Temp Table to find sales values grouped dates; 
2) Create another CTE/Temp table with a rank windowed function on the previous query to create 
"best day" and "worst day"; 
3) Query the second temp table twice, once for the best day, once for the worst day, 
with a UNION binding them. */
--QUERY 7

WITH sales_by_date AS (
    SELECT
        market_date,
        SUM(quantity * cost_per_quantity) AS total_sales
    FROM customer_purchases
    GROUP BY market_date
),
ranked_sales AS (
    SELECT
        market_date,
        total_sales,
        RANK() OVER (ORDER BY total_sales DESC) AS best_rank,
        RANK() OVER (ORDER BY total_sales ASC) AS worst_rank
    FROM sales_by_date
)
SELECT
    market_date,
    total_sales,
    'best day' AS day_type
FROM ranked_sales
WHERE best_rank = 1
UNION
SELECT
    market_date,
    total_sales,
    'worst day' AS day_type
FROM ranked_sales
WHERE worst_rank = 1
ORDER BY day_type, market_date;

--END QUERY



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
--QUERY 8

WITH customer_count AS (
  SELECT COUNT(*) AS number_of_customers
  FROM customer
),
vendor_products AS (
  SELECT
    v_i.vendor_id,
    v_i.product_id,
    v_i.original_price
  FROM vendor_inventory AS v_i
)
SELECT
  v.vendor_name,
  p.product_name,
  v_p.original_price AS unit_price,
  5 AS units_per_customer,
  c_c.number_of_customers,
  (5 * c_c.number_of_customers) AS total_units_sold,
  (v_p.original_price * 5 * c_c.number_of_customers) AS profit
FROM vendor_products AS v_p
JOIN vendor  AS v ON v.vendor_id  = v_p.vendor_id
JOIN product AS p ON p.product_id = v_p.product_id
CROSS JOIN customer_count AS c_c
ORDER BY v.vendor_name, p.product_name;

--END QUERY


-- INSERT
/*1.  Create a new table "product_units". 
This table will contain only products where the `product_qty_type = 'unit'`. 
It should use all of the columns from the product table, as well as a new column for the `CURRENT_TIMESTAMP`.  
Name the timestamp column `snapshot_timestamp`. */
--QUERY 9

CREATE TABLE product_units AS
SELECT
    p.*,
    CURRENT_TIMESTAMP AS snapshot_timestamp
FROM product AS p
WHERE p.product_qty_type = 'unit';

SELECT * FROM product_units;

--END QUERY


/*2. Using `INSERT`, add a new row to the product_units table (with an updated timestamp). 
This can be any product you desire (e.g. add another record for Apple Pie). */
--QUERY 10

INSERT INTO product_units (
  product_id,
  product_name,
  product_size,
  product_qty_type,
  snapshot_timestamp
)
SELECT
  p.product_id,
  p.product_name,
  p.product_size,
  p.product_qty_type,
  CURRENT_TIMESTAMP AS snapshot_timestamp
FROM product AS p
WHERE p.product_name = 'Apple Pie'
  AND p.product_qty_type = 'unit';

SELECT * FROM product_units;

--END QUERY


-- DELETE
/* 1. Delete the older record for whatever product you added. 

HINT: If you don't specify a WHERE clause, you are going to have a bad time.*/
--QUERY 11

DELETE FROM product_units
WHERE rowid IN (
  SELECT rowid
  FROM product_units
  WHERE product_name = 'Apple Pie'
  ORDER BY snapshot_timestamp ASC
  LIMIT 1
);
SELECT * FROM product_units;

--END QUERY


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
--QUERY 12

ALTER TABLE product_units
ADD current_quantity INT;

/*This option assumes vendor_inventory has:
product_id
quantity
a column that defines “latest”, such as market_date, snapshot_timestamp, inventory_date, or a surrogate key like vendor_inventory_id.
Version using a date/timestamp column (replace vi.inventory_timestam */

UPDATE product_units AS p_u
SET current_quantity = COALESCE((
  SELECT v_i.quantity
  FROM vendor_inventory AS v_i
  WHERE v_i.product_id = p_u.product_id
  ORDER BY v_i.product_id DESC
  LIMIT 1
), 0)
WHERE p_u.product_id IS NOT NULL;

SELECT * FROM product_units;

--END QUERY



