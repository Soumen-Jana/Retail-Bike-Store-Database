-- Retrieve all orders placed by customers, including order date and customer name.

select c.first_name, c.last_name, o.order_date
from customers as c
join orders as o
on o.customer_id= c.customer_id;

-- Retrieve the details of all items purchased in a particular order.

SELECT oi.order_id, p.product_name, oi.quantity, oi.list_price
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
WHERE oi.order_id = 1;     

-- List all staff members and the stores they are associated with.

select st.first_name, st.last_name, s.store_name
from staffs as st
join stores as s on s.store_id = st.store_id;     
														

-- Calculate the total sales made by each store.

SELECT st.store_name, round(SUM(oi.list_price * oi.quantity),2) AS total_sales
FROM stores st
JOIN orders o ON st.store_id = o.store_id
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY st.store_name
order by total_sales desc;

-- Identify the top 5 best-selling products based on quantity sold.

SELECT 
    p.product_name, SUM(oi.quantity) AS total_sold
FROM
    products p
        JOIN
    order_items oi ON p.product_id = oi.product_id
GROUP BY p.product_name
ORDER BY total_sold DESC
LIMIT 5;

-- Find the number of orders each customer has placed.

SELECT 
    c.first_name, c.last_name, COUNT(o.order_id) AS num_orders
FROM
    customers c
        JOIN
    orders o ON c.customer_id = o.customer_id
GROUP BY c.first_name , c.last_name;

-- Calculate the total sales per product category.

SELECT 
    cat.category_name,
    round(SUM(oi.quantity * oi.list_price),3) AS total_sales
FROM
    categories cat
        JOIN
    products p ON cat.category_id = p.category_id
        JOIN
    order_items oi ON p.product_id = oi.product_id
GROUP BY cat.category_name;

-- List all products that have less than 10 units in stock in each store.

SELECT 
    st.store_name, p.product_name, s.quantity
FROM
    stocks s
        JOIN
    products p ON s.product_id = p.product_id
        JOIN
    stores st ON s.store_id = st.store_id
WHERE
    s.quantity < 10;
    
-- Calculate the total value of orders placed by each customer, considering all their orders.

SELECT 
    c.customer_id,
    c.first_name,
    c.last_name,
    round(SUM(oi.list_price * oi.quantity),2) AS lifetime_value
FROM
    customers c
        JOIN
    orders o ON c.customer_id = o.customer_id
        JOIN
    order_items oi ON o.order_id = oi.order_id
GROUP BY c.customer_id , c.first_name , c.last_name
ORDER BY lifetime_value DESC;

-- Calculate the total sales for each month.

SELECT 
    EXTRACT(MONTH FROM o.order_date) AS month,
    round(SUM(oi.list_price * oi.quantity),2) AS total_sales
FROM
    orders o
        JOIN
    order_items oi ON o.order_id = oi.order_id
GROUP BY month
ORDER BY month;

-- Rank products within each category based on the total quantity sold using window functions.

SELECT p.product_name, c.category_name, SUM(oi.quantity) AS total_sold,
       RANK() OVER (PARTITION BY c.category_name ORDER BY SUM(oi.quantity) DESC) AS rank_in_category
FROM products p
JOIN categories c ON p.category_id = c.category_id
JOIN order_items oi ON p.product_id = oi.product_id
GROUP BY p.product_name, c.category_name;

-- Calculate the average delay between the required_date and the shipped_date of each order.

SELECT 
    o.order_id,
    o.required_date,
    o.shipped_date,
    DATEDIFF(o.shipped_date, o.required_date) AS delay_days
FROM
    orders o
WHERE
    o.shipped_date IS NOT NULL;

-- identify products that need restocking (less than 20 units in stock across all stores).

WITH stock_levels AS (
    SELECT p.product_name, SUM(s.quantity) AS total_quantity
    FROM products p
    JOIN stocks s ON p.product_id = s.product_id
    GROUP BY p.product_name
)
SELECT product_name, total_quantity
FROM stock_levels
WHERE total_quantity < 20;

-- Calculate the frequency at which customers make purchases, and assign them into tiers (e.g., "Frequent Buyers", "Occasional Buyers").

WITH customer_orders AS (
    SELECT c.customer_id, c.first_name, c.last_name, COUNT(o.order_id) AS order_count
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY c.customer_id, c.first_name, c.last_name
)
SELECT customer_id, first_name, last_name, order_count,
       CASE 
           WHEN order_count > 10 THEN 'Frequent Buyer'
           WHEN order_count BETWEEN 5 AND 10 THEN 'Regular Buyer'
           ELSE 'Occasional Buyer'
       END AS customer_tier
FROM customer_orders;

-- Calculate the percentage of customers who have made more than one order.

WITH customer_order_count AS (
    SELECT customer_id, COUNT(order_id) AS order_count
    FROM orders
    GROUP BY customer_id
)
SELECT (COUNT(CASE WHEN order_count > 1 THEN 1 END) * 100.0 / COUNT(*)) AS repeat_customer_rate
FROM customer_order_count;

-- For each store, find the top-selling product categories by total sales.

SELECT 
    st.store_name,
    c.category_name,
    round(SUM(oi.quantity * oi.list_price),2 )AS total_sales
FROM
    stores st
        JOIN
    orders o ON st.store_id = o.store_id
        JOIN
    order_items oi ON o.order_id = oi.order_id
        JOIN
    products p ON oi.product_id = p.product_id
        JOIN
    categories c ON p.category_id = c.category_id
GROUP BY st.store_name , c.category_name
ORDER BY st.store_name , total_sales DESC;
 
