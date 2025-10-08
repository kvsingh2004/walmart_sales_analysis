-- Q1: Find different payment method and number of transactions, number of qty sold
SELECT payment_method,
    COUNT(*) AS no_of_payments,
    SUM(quantity) AS total_quantity
FROM walmart_cleaned_data 
GROUP BY payment_method;

-- Q2: Identify the highest-rated category in each branch, displaying the branch and category (based on AVG rating)
SELECT branch, category
FROM (
    SELECT 
        branch, 
        category, 
        AVG(rating) AS avg_rating,
        DENSE_RANK() OVER (PARTITION BY branch ORDER BY AVG(rating) DESC) AS rnk
    FROM walmart_cleaned_data 
    GROUP BY branch, category
) ranked
WHERE rnk = 1;

-- Q3: Identify the busiest day for each branch based on the number of transactions
SELECT branch, day_name, cnt
FROM (
    SELECT 
        branch, 
        DATE_FORMAT(STR_TO_DATE(date, '%d/%m/%y'), '%W') AS day_name,
        COUNT(*) as cnt,
        RANK() OVER (PARTITION BY branch ORDER BY COUNT(*) DESC) AS rnk
    FROM walmart_cleaned_data
    GROUP BY branch, day_name
) t
WHERE rnk = 1;

-- Q4: Calculate the total quantity of items sold per payment method
SELECT payment_method, SUM(quantity) AS total_quantity
FROM walmart_cleaned_data
GROUP BY payment_method;

-- Q5: Determine the average, minimum, and maximum rating of category for each city
SELECT city, 
       category,
       ROUND(AVG(rating), 2) AS average_rating, 
       MIN(rating) AS minimum_rating, 
       MAX(rating) AS maximum_rating
FROM walmart_cleaned_data 
GROUP BY city, category;

-- Q6: Calculate the total profit for each category, ordered from highest to lowest profit
SELECT category, 
       ROUND(SUM(total), 2) AS total_revenue, 
       ROUND(SUM(total * profit_margin), 2) AS total_profit 
FROM walmart_cleaned_data 
GROUP BY category
ORDER BY total_profit DESC;

-- Q7: Determine the most common payment method for each Branch
SELECT branch, payment_method
FROM (
    SELECT 
        branch,
        payment_method,
        RANK() OVER (PARTITION BY branch ORDER BY COUNT(*) DESC) AS rnk
    FROM walmart_cleaned_data
    GROUP BY branch, payment_method
) t
WHERE rnk = 1;

-- Q8: Categorize sales into 3 groups (MORNING, AFTERNOON, EVENING) and find out each shift and number of invoices
SELECT 
    branch,
    CASE 
        WHEN HOUR(STR_TO_DATE(time, '%H:%i:%s')) < 12 THEN 'Morning'
        WHEN HOUR(STR_TO_DATE(time, '%H:%i:%s')) BETWEEN 12 AND 17 THEN 'Afternoon'
        ELSE 'Evening'
    END AS day_time,
    COUNT(*) AS num_invoices
FROM walmart_cleaned_data
GROUP BY branch, day_time
ORDER BY branch, num_invoices DESC;

-- Q9: Identify 5 branches with the highest decrease ratio in revenue compared to last year (2023 vs 2022)
WITH revenue_2022 AS (
    SELECT branch, 
           SUM(total) AS revenue
    FROM walmart_cleaned_data 
    WHERE YEAR(STR_TO_DATE(date, '%d/%m/%y')) = 2022 
    GROUP BY branch
),
revenue_2023 AS (
    SELECT branch,
           SUM(total) AS revenue
    FROM walmart_cleaned_data
    WHERE YEAR(STR_TO_DATE(date, '%d/%m/%y')) = 2023
    GROUP BY branch
)
SELECT ls.branch,
       ls.revenue AS last_year_revenue,
       cs.revenue AS current_year_revenue,
       ROUND((cs.revenue - ls.revenue) / ls.revenue * 100, 2) AS rev_dec_ratio
FROM revenue_2022 ls
JOIN revenue_2023 cs ON ls.branch = cs.branch
WHERE ls.revenue > cs.revenue 
ORDER BY rev_dec_ratio DESC
LIMIT 5;
