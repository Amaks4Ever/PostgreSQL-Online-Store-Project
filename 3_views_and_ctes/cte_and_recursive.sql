
--Average total amount per customer using CTE.
WITH avg_table as(
    SELECT 
        c.first_name,
        c.last_name,
        SUM(o.total_amount) as sum_amount
    FROM orders o
    JOIN customers c ON o.customer_id = c.id
    GROUP BY c.first_name, c.last_name 
) 
SELECT * FROM avg_table;

--Products with prices above average using CTE.
WITH avg_price as(
    SELECT 
        AVG(price) as avp
    FROM products
)
SELECT 
    p.name,
    p.category,
    p.price,
    ROUND(avg_price.avp,2) as avg_price
FROM 
    products p,
    avg_price
WHERE p.price > avg_price.avp;

--Number of orders by month using CTE.
WITH ord_month as(
    SELECT
    TO_CHAR(order_date::DATE, 'YYYY-MM') as date,
    COUNT(*)
    FROM orders
    GROUP BY TO_CHAR(order_date::DATE, 'YYYY-MM')
)
SELECT * FROM ord_month 
ORDER BY date;

--Customers whose order total is above average using CTE + JOIN.
WITH sum_total as(
    SELECT 
    c.first_name,
    c.last_name,
    SUM(o.total_amount) as sum_t
    FROM orders o
    JOIN customers c ON o.customer_id = c.id
    GROUP BY c.first_name,c.last_name
), avg_sum as(
    SELECT 
    ROUND(AVG(sum_t)) as avg_s
    FROM sum_total
)
SELECT *
FROM sum_total s, avg_sum a
WHERE s.sum_t > a.avg_s;

--Recursive generation: produce numbers from 1 to 10.
WITH RECURSIVE org_chart(num) AS (
SELECT 
1 as num
UNION ALL
SELECT 
num+1 
FROM org_chart
WHERE num<=10
)
SELECT * FROM org_chart;

--Recursively generate all dates of the current month.
WITH RECURSIVE calendar(dat) as(
    SELECT 
    DATE_TRUNC('month', CURRENT_DATE)
    UNION ALL
    SELECT dat + INTERVAL '1 day'
    FROM calendar
    WHERE dat + INTERVAL '1 day' < DATE_TRUNC('month', CURRENT_DATE + INTERVAL '1 month')  
)
SELECT dat
FROM calendar;

--Average total order amount by country using CTE.
WITH avg_total_amount as (
    SELECT 
    c.country,
    ROUND(AVG(o.total_amount),2)
    FROM orders o
    JOIN customers c ON o.customer_id = c.id
    GROUP BY c.country
)
SELECT * FROM avg_total_amount;
