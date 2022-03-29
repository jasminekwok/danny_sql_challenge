/* --------------------
   Case Study Questions
   --------------------*/

-- 1. What is the total amount each customer spent at the restaurant?
#STEPS 
## 1. Join sales on menu 
## 2. match product_id on both 
## 3. Group by customer 
## 4. sum product price 
 
SELECT 
	customer_id,
    SUM(price) AS total_spending 
FROM sales s
JOIN menu m
    ON s.product_id = m.product_id
GROUP BY customer_id; 

-- 2. How many days has each customer visited the restaurant?
#STEPS 
## 1.  Group by customer_id 
## 2.  Count Distinct dates 

SELECT 
	customer_id, 
    COUNT(DISTINCT order_date) AS number_of_visits 
FROM sales 
GROUP BY customer_id; 

-- 3. What was the first item from the menu purchased by each customer? 
#STEPS 
## 1.  filter earliest date 
## 2.  join on sales again to get product_id 
## 3.  join on menu to get product name 

SELECT 
	e_sales.customer_id,
    product_name
FROM (
	SELECT 
		customer_id, 
		MIN(order_date) AS earliest_date
	FROM sales s
	GROUP BY customer_id) AS e_sales
LEFT JOIN sales s 
	ON e_sales.customer_id = s.customer_id
	AND e_sales.earliest_date = s.order_date
JOIN menu m
	ON s.product_id = m.product_id; 


-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
#STEPS 
## 1.  JOIN sales and menu  
## 2.  match on product_id 
## 3.  count product_id 
## 4.  group by product_id 
## 5.  order by purchase count desc 
## 6.  filter maximum 

SELECT 
	m.product_name, 
    COUNT(m.product_id) AS total_purchase
FROM sales s 
JOIN menu m 
	ON s.product_id = m.product_id 
GROUP BY m.product_name
ORDER BY COUNT(m.product_id) DESC 
LIMIT 1; 

-- 5. Which item was the most popular for each customer?
#STEPS 
## 1.  count the product bought and find the MAX - using row_number() OVER (PARTITION BY...) 
## 2.  group by customer and product 
## 3.  join to get the product name

SELECT 
	ranking_table.customer_id, 
    m.product_name,
    ranking_table.purchase_count
FROM (SELECT 
	customer_id,
    product_id,
	COUNT(product_id) AS purchase_count,
    ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY COUNT(product_id) DESC) AS purchase_rank
FROM sales
GROUP BY customer_id, product_id ) AS ranking_table
JOIN menu m 
	ON m.product_id = ranking_table.product_id
WHERE purchase_rank = 1
ORDER BY 1;
 
-- 6. Which item was purchased first by the customer after they became a member?
#STEPS 
## 1. join members and sales on customer_id 
## 2. check that join date is less than or equal to order date
## 3. dense_rank by order_date 
## 4. join menu on product_id to get purchase_name 

SELECT 
	r_table.customer_id, 
    r_table.join_date,
    r_table.order_date,
    product_name
FROM (
SELECT 
	mb.customer_id, 
    join_date, 
    order_date, 
    product_id,
    DENSE_RANK() OVER (PARTITION BY customer_id ORDER BY order_date) AS date_rank 
FROM members mb 
JOIN sales s
	ON mb.customer_id = s.customer_id 
WHERE order_date >= join_date) AS r_table 
JOIN menu m 
	ON m.product_id = r_table.product_id
WHERE r_table.date_rank = 1
ORDER BY 1; 


-- 7. Which item was purchased just before the customer became a member?
#STEPS
## 1. join members and sales on customer_id 
## 2. check that join date is greater than order date and the order date is the largest 
## 3. join with menu on product_id 

SELECT 
	r_table.customer_id,
    r_table.join_date,
    r_table.order_date,
    product_name
FROM(
SELECT 
	s.customer_id, 
    join_date,
    order_date,
    s.product_id,
	DENSE_RANK() OVER (PARTITION BY customer_id ORDER BY order_date DESC)  AS date_rank
FROM members mb
JOIN sales s
	ON mb.customer_id = s.customer_id
WHERE join_date > order_date) AS r_table 
JOIN menu m 
	ON m.product_id = r_table.product_id
WHERE r_table.date_rank = 1
ORDER BY 1; 

-- 8. What is the total items and amount spent for each member before they became a member?
#STEPS: 
## 1. get join date by join sales and members on customer_id
## 2. group by customer_id and filter date before join date 
## 3. join to menu by product_id to get price 
## 4. SUM price to get total 

SELECT 
	customer_id, 
    COUNT(DISTINCT m.product_id) AS total_items,
    SUM(price) AS total_spending
FROM (
SELECT 
	m.customer_id, 
	join_date, 
    order_date, 
    product_id
FROM members m 
JOIN sales s 
	ON m.customer_id = s.customer_id 
WHERE order_date < join_date) AS member_sales
JOIN menu m
	ON m.product_id = member_sales.product_id
GROUP BY customer_id;


-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
#STEPS: 
## 1. join sales to menu to get product name 
## 2. create a 'points' column corresponding to each product 
## 3. sum to find total points 
## 4. group by customer_id 


SELECT 
	customer_id,
    SUM(points) AS total_points
FROM (
SELECT 
	customer_id, 
    product_name, 
    CASE 
		WHEN product_name LIKE 'sushi' THEN price*10*2
        ELSE price*10 
        END AS points 
FROM sales s 
JOIN menu m 
	ON s.product_id = m.product_id) AS points_table
GROUP BY customer_id; 


-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
#STEPS: 
## 1. join members and sales on customer_id 
## 2. join on menu table to get price 
## 3. case when to add new points column and filter by join date and end of january 
## 4. sum total points 
## 5. group by customer_id

SELECT 
	customer_id,
    SUM(points) AS total_points 
FROM (
SELECT
	mb.customer_id, 
    mb.join_date, 
    s.order_date,
    m.product_name,
    m.price,
    CASE 
		WHEN product_name LIKE 'SUSHI' THEN price*10*2
        WHEN order_date >= join_date AND order_date <= DATE_ADD(join_date, INTERVAL 6 DAY) THEN price*10*2
        ELSE price*10
        END AS points 
FROM members mb 
JOIN sales s 
	ON mb.customer_id = s.customer_id
JOIN menu m
	ON s.product_id = m.product_id
WHERE order_date <= '2021-01-31') AS points_table
GROUP BY customer_id
ORDER BY 1; 
