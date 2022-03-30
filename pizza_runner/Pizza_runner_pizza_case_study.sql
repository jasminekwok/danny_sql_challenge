## Pizza Metrics

### Clean up Tables 
# runner_orders 
UPDATE runner_orders SET pickup_time = NULL WHERE pickup_time = 'null'; 
UPDATE runner_orders SET distance = NULL WHERE distance = 'null'; 
UPDATE runner_orders SET duration = NULL WHERE duration = 'null'; 
UPDATE runner_orders SET cancellation = NULL WHERE cancellation = 'null' OR cancellation = ''; 
# customer_orders 
UPDATE customer_orders SET exclusions = NULL WHERE exclusions = 'null' OR exclusions = ''; 
UPDATE customer_orders SET extras = NULL WHERE extras = 'null' OR extras = ''; 

-- 1. How many pizzas were ordered?
SELECT 
	COUNT(order_id) AS total_pizzas
FROM customer_orders;

-- How many unique customer orders were made?
SELECT 
	COUNT(DISTINCT customer_id) AS unique_customers
FROM customer_orders;

-- How many successful orders were delivered by each runner?
SELECT 
	runner_id,
    COUNT(pickup_time) AS successful_orders
FROM runner_orders
WHERE pickup_time IS NOT null
GROUP BY runner_id; 

-- How many of each type of pizza was delivered?
SELECT 
	p.pizza_name,
    c.pizza_id,
    COUNT(pickup_time) AS successful_orders
FROM runner_orders r
JOIN customer_orders c
	ON c.order_id = r.order_id
JOIN pizza_names p 
	ON c.pizza_id = p.pizza_id
WHERE pickup_time IS NOT null
GROUP BY c.pizza_id, p.pizza_name; 

-- How many Vegetarian and Meatlovers were ordered by each customer?
SELECT  
    c.customer_id,
	p.pizza_name,
	COUNT(c.pizza_id) AS pizza_counts 
FROM pizza_names p 
JOIN customer_orders c
	ON c.pizza_id = p.pizza_id
GROUP BY c.customer_id, p.pizza_name; 

-- What was the maximum number of pizzas delivered in a single order?
SELECT 
    order_id,
    COUNT(pizza_id) AS Max_pizza_order
FROM customer_orders
GROUP BY order_id
ORDER BY Max_pizza_order DESC
LIMIT 1; 

-- For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
# ASSUMPTION: change meant adding extras or removing toppings 
SELECT 
	customer_id,
	SUM(CASE 
		WHEN exclusions IS NOT NULL OR extras IS NOT NULL THEN 1 
        ELSE 0 
        END) AS AtLeastOneChange, 
	SUM(CASE 
		WHEN exclusions IS NULL AND extras IS NULL THEN 1 
        ELSE 0 
        END) AS NoChange
FROM customer_orders
GROUP BY customer_id; 


-- How many pizzas were delivered that had both exclusions and extras?
SELECT 
	customer_id,
	SUM(CASE
		WHEN exclusions IS NOT NULL AND extras IS NOT NULL THEN 1 
        ELSE 0 
        END) AS BothExclusionAndExtra
FROM customer_orders
GROUP BY customer_id; 


-- What was the total volume of pizzas ordered for each hour of the day?
SELECT 
	EXTRACT(HOUR FROM order_time) AS HourData, 
    COUNT(order_id) AS OrderCount
FROM customer_orders
GROUP BY HourData;

-- What was the volume of orders for each day of the week?
SELECT 
	DAYNAME(order_time) AS WeekOfDay, 
    COUNT(order_id) AS OrderCount
FROM customer_orders
GROUP BY WeekOfDay;