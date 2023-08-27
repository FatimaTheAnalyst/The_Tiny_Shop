CREATE TABLE customers (
    customer_id integer PRIMARY KEY,
    first_name varchar(100),
    last_name varchar(100),
    email varchar(100)
)

CREATE TABLE products (
    product_id integer PRIMARY KEY,
    product_name varchar(100),
    price decimal
)

CREATE TABLE orders (
    order_id integer PRIMARY KEY,
    customer_id integer,
    order_date date
)

CREATE TABLE order_items (
    order_id integer,
    product_id integer,
    quantity integer
)

INSERT INTO customers (customer_id, first_name, last_name, email) VALUES
(1, 'John', 'Doe', 'johndoe@email.com'),
(2, 'Jane', 'Smith', 'janesmith@email.com'),
(3, 'Bob', 'Johnson', 'bobjohnson@email.com'),
(4, 'Alice', 'Brown', 'alicebrown@email.com'),
(5, 'Charlie', 'Davis', 'charliedavis@email.com'),
(6, 'Eva', 'Fisher', 'evafisher@email.com'),
(7, 'George', 'Harris', 'georgeharris@email.com'),
(8, 'Ivy', 'Jones', 'ivyjones@email.com'),
(9, 'Kevin', 'Miller', 'kevinmiller@email.com'),
(10, 'Lily', 'Nelson', 'lilynelson@email.com'),
(11, 'Oliver', 'Patterson', 'oliverpatterson@email.com'),
(12, 'Quinn', 'Roberts', 'quinnroberts@email.com'),
(13, 'Sophia', 'Thomas', 'sophiathomas@email.com')

INSERT INTO products (product_id, product_name, price) VALUES
(1, 'Product A', 10.00),
(2, 'Product B', 15.00),
(3, 'Product C', 20.00),
(4, 'Product D', 25.00),
(5, 'Product E', 30.00),
(6, 'Product F', 35.00),
(7, 'Product G', 40.00),
(8, 'Product H', 45.00),
(9, 'Product I', 50.00),
(10, 'Product J', 55.00),
(11, 'Product K', 60.00),
(12, 'Product L', 65.00),
(13, 'Product M', 70.00)

INSERT INTO orders (order_id, customer_id, order_date) VALUES
(1, 1, '2023-05-01'),
(2, 2, '2023-05-02'),
(3, 3, '2023-05-03'),
(4, 1, '2023-05-04'),
(5, 2, '2023-05-05'),
(6, 3, '2023-05-06'),
(7, 4, '2023-05-07'),
(8, 5, '2023-05-08'),
(9, 6, '2023-05-09'),
(10, 7, '2023-05-10'),
(11, 8, '2023-05-11'),
(12, 9, '2023-05-12'),
(13, 10, '2023-05-13'),
(14, 11, '2023-05-14'),
(15, 12, '2023-05-15'),
(16, 13, '2023-05-16')

INSERT INTO order_items (order_id, product_id, quantity) VALUES
(1, 1, 2),
(1, 2, 1),
(2, 2, 1),
(2, 3, 3),
(3, 1, 1),
(3, 3, 2),
(4, 2, 4),
(4, 3, 1),
(5, 1, 1),
(5, 3, 2),
(6, 2, 3),
(6, 1, 1),
(7, 4, 1),
(7, 5, 2),
(8, 6, 3),
(8, 7, 1),
(9, 8, 2),
(9, 9, 1),
(10, 10, 3),
(10, 11, 2),
(11, 12, 1),
(11, 13, 3),
(12, 4, 2),
(12, 5, 1),
(13, 6, 3),
(13, 7, 2),
(14, 8, 1),
(14, 9, 2),
(15, 10, 3),
(15, 11, 1),
(16, 12, 2),
(16, 13, 3)

-- 1) Which product has the highest price? Only return a single row?

SELECT *
FROM products
WHERE price = (SELECT MAX(price) FROM products)


-- 2) Which customer has made the most orders?

SELECT first_name, last_name, quantity
FROM (customers c JOIN orders o ON c.customer_id = o.customer_id)
JOIN order_items oi ON o.order_id = oi.order_id
WHERE quantity = (SELECT MAX(quantity) FROM order_items)

-- 3) What’s the total revenue per product?

SELECT product_name, price * quantity AS revenue
from products p
join order_items oi
on p.product_id = oi.product_id
Order by revenue Desc

-- 4) Find the day with the highest revenue.

DROP TABLE IF EXISTS #temp_revenue
CREATE TABLE #temp_revenue(
order_id integer,
quantity numeric,
price float,
revenue numeric)

INSERT INTO #temp_revenue
SELECT order_id, quantity, price, price * quantity
FROM products p
JOIN order_items oi
ON p.product_id = oi.product_id

SELECT order_date, revenue
FROM #temp_revenue r
JOIN orders o
ON o.order_id = r.order_id
WHERE revenue = (SELECT MAX(revenue) FROM #temp_revenue)

-- 5) Find the first order (by date) for each customer.

SELECT o.customer_id, first_name, last_name, MIN(order_date) AS first_order
FROM orders o
FULL JOIN customers c
ON o.customer_id = c.customer_id
GROUP BY o.customer_id, first_name, last_name

-- 6) Find the top 3 customers who have ordered the most distinct products.

With CTE_customer AS( 
SELECT customer_id, COUNT(DISTINCT product_id) distinct_products_count
FROM orders o
JOIN order_items oi 
ON o.order_id = oi.order_id
GROUP BY customer_id)

SELECT top 3 first_name, last_name, distinct_products_count
FROM CTE_customer cte
JOIN customers c
ON cte.customer_id  = c.customer_id


--7) Which product has been bought the least in terms of quantity?

SELECT product_name, quantity
FROM order_items oi
JOIN products p
ON oi.order_id = p.product_id
WHERE quantity = (SELECT MIN(quantity) FROM order_items )



--8) What is the median order total?

WITH CTE_order AS(
SELECT order_id, SUM(quantity * price) AS total_revenue, 
ROW_NUMBER() OVER (ORDER BY SUM(quantity * price)) AS row_number,
COUNT(*) OVER() AS total_orders
FROM order_items io
FULL JOIN products p
ON io.product_id= p.product_id
GROUP BY order_id
)
SELECT total_revenue AS media_order_total
FROM CTE_order
WHERE row_number = ROUND(total_orders/2, 1)


--9) For each order, determine if it was ‘Expensive’ (total over 300),
-- ‘Affordable’ (total over 100), or ‘Cheap’.

WITH CTE_revenue_per_order AS(
SELECT order_id, SUM(quantity * price) AS total_revenue
FROM order_items io
FULL JOIN products p
ON io.product_id= p.product_id
GROUP BY order_id )

SELECT *,
CASE
	WHEN total_revenue >= 300 THEN 'Expensive'
	WHEN total_revenue >= 100 THEN 'Affordable'
	ELSE 'CHEAP' 
	END AS affordability
FROM CTE_revenue_per_order


--10) Find customers who have ordered the product with the highest price.

SELECT CONCAT(first_name,' ',last_name) AS customer, product_name, price
FROM order_items oi
JOIN products p
on oi.product_id = p.product_id
Join orders o
on o.order_id = oi.order_id
JOIN customers c
on c.customer_id = o.customer_id
WHERE price = (SELECT MAX(price) FROM products)

