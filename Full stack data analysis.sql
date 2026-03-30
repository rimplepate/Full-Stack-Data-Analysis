select * from customer_feedback;
select * from customers;
select * from marketing_campaigns;
select * from orders;
select * from products;

-- Check for missing values per column from customers table
SELECT 
    SUM(CASE WHEN name IS NULL THEN 1 ELSE 0 END) AS missing_name,
    SUM(CASE WHEN age IS NULL THEN 1 ELSE 0 END) AS missing_age,
    SUM(CASE WHEN gender IS NULL THEN 1 ELSE 0 END) AS missing_gender,
    SUM(CASE WHEN location IS NULL THEN 1 ELSE 0 END) AS missing_location,
    SUM(CASE WHEN signup_date IS NULL THEN 1 ELSE 0 END) AS missing_signup_date,
    SUM(CASE WHEN customer_segment IS NULL THEN 1 ELSE 0 END) AS missing_segment
FROM customers;

-- Orders
SELECT
    SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END) AS missing_order_id,
    SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) AS missing_customer_id,
    SUM(CASE WHEN order_date IS NULL THEN 1 ELSE 0 END) AS missing_order_date,
    SUM(CASE WHEN order_amount IS NULL THEN 1 ELSE 0 END) AS missing_order_amount,
    SUM(CASE WHEN payment_type IS NULL THEN 1 ELSE 0 END) AS missing_payment_type,
    SUM(CASE WHEN shipping_type IS NULL THEN 1 ELSE 0 END) AS missing_shipping_type,
    SUM(CASE WHEN order_status IS NULL THEN 1 ELSE 0 END) AS missing_order_status
FROM orders;

-- Products
SELECT
    SUM(CASE WHEN product_id IS NULL THEN 1 ELSE 0 END) AS missing_product_id,
    SUM(CASE WHEN category IS NULL THEN 1 ELSE 0 END) AS missing_category,
    SUM(CASE WHEN product_name IS NULL THEN 1 ELSE 0 END) AS missing_product_name,
    SUM(CASE WHEN price IS NULL THEN 1 ELSE 0 END) AS missing_price,
    SUM(CASE WHEN inventory_count IS NULL THEN 1 ELSE 0 END) AS missing_inventory
FROM products;

-- Marketing Campaigns
SELECT
    SUM(CASE WHEN campaign_id IS NULL THEN 1 ELSE 0 END) AS missing_campaign_id,
    SUM(CASE WHEN campaign_name IS NULL THEN 1 ELSE 0 END) AS missing_campaign_name,
    SUM(CASE WHEN channel IS NULL THEN 1 ELSE 0 END) AS missing_channel,
    SUM(CASE WHEN start_date IS NULL THEN 1 ELSE 0 END) AS missing_start_date,
    SUM(CASE WHEN end_date IS NULL THEN 1 ELSE 0 END) AS missing_end_date,
    SUM(CASE WHEN budget IS NULL THEN 1 ELSE 0 END) AS missing_budget,
    SUM(CASE WHEN clicks IS NULL THEN 1 ELSE 0 END) AS missing_clicks,
    SUM(CASE WHEN conversions IS NULL THEN 1 ELSE 0 END) AS missing_conversions
FROM marketing_campaigns;

-- Customer Feedback
SELECT
    SUM(CASE WHEN feedback_id IS NULL THEN 1 ELSE 0 END) AS missing_feedback_id,
    SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) AS missing_customer_id,
    SUM(CASE WHEN product_id IS NULL THEN 1 ELSE 0 END) AS missing_product_id,
    SUM(CASE WHEN rating IS NULL THEN 1 ELSE 0 END) AS missing_rating,
    SUM(CASE WHEN review IS NULL THEN 1 ELSE 0 END) AS missing_review,
    SUM(CASE WHEN feedback_date IS NULL THEN 1 ELSE 0 END) AS missing_feedback_date
FROM customer_feedback;

-- 4. Duplicate check
-- Customers
SELECT customer_id, COUNT(*) AS duplicate_count
FROM customers
GROUP BY customer_id
HAVING COUNT(*) > 1;

-- Orders
SELECT order_id, COUNT(*) AS duplicate_count
FROM orders
GROUP BY order_id
HAVING COUNT(*) > 1;

-- Products
SELECT product_id, COUNT(*) AS duplicate_count
FROM products
GROUP BY product_id
HAVING COUNT(*) > 1;

-- Marketing Campaigns
SELECT campaign_id, COUNT(*) AS duplicate_count
FROM marketing_campaigns
GROUP BY campaign_id
HAVING COUNT(*) > 1;

-- Customer Feedback
SELECT feedback_id, COUNT(*) AS duplicate_count
FROM customer_feedback
GROUP BY feedback_id
HAVING COUNT(*) > 1;

-- Check duplicates again
SELECT customer_id, COUNT(*) AS duplicate_count
FROM customers
GROUP BY customer_id
HAVING COUNT(*) > 1;

-- Total sales per month 
SELECT 
    DATE_FORMAT(order_date, '%Y-%m-01') AS month, 
    COUNT(order_id) AS total_orders,
    SUM(order_amount) AS total_revenue,
    AVG(order_amount) AS avg_order_value
FROM orders
WHERE order_status = 'Delivered'
GROUP BY month
ORDER BY month;

SELECT 
    DATE_TRUNC('month', order_date) AS order_month,
    COUNT(order_id) AS total_orders,
    SUM(order_amount) AS total_revenue,
    AVG(order_amount) AS average_order_value
FROM orders
WHERE order_status = 'Delivered'
GROUP BY 1
ORDER BY 1;

-- top customers
SELECT 
    c.customer_id,
    c.name,
    c.customer_segment,
    COUNT(o.order_id) AS total_orders,
    SUM(o.order_amount) AS lifetime_value,
    MAX(o.order_date) AS last_purchase_date
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.name, c.customer_segment
ORDER BY lifetime_value DESC
LIMIT 10;

-- campaign performance
SELECT 
    campaign_name,
    channel,
    budget,
    clicks,
    conversions,
    ROUND((conversions * 1.0 / NULLIF(clicks, 0)) * 100, 2) AS conversion_rate_pct,
    ROUND(budget / NULLIF(conversions, 0), 2) AS cost_per_conversion
FROM marketing_campaigns
ORDER BY conversion_rate_pct DESC;

-- top products
SELECT 
    p.product_name,
    p.category,
    COUNT(f.feedback_id) AS review_count,
    ROUND(AVG(f.rating), 2) AS average_rating,
    p.inventory_count
FROM products p
LEFT JOIN customer_feedback f ON p.product_id = f.product_id
GROUP BY p.product_id, p.product_name, p.category, p.inventory_count
ORDER BY review_count DESC, average_rating DESC;

-- churn analysis (customers inactive > 6 months)
-- First, identify the "current" date of the dataset
SET @latest_order = (SELECT MAX(order_date) FROM orders);

-- Identify churned customers
SELECT 
    c.customer_id,
    c.name,
    c.customer_segment,
    MAX(o.order_date) AS last_purchase_date,
    DATEDIFF(@latest_order, MAX(o.order_date)) AS days_since_last_purchase
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.name, c.customer_segment
HAVING days_since_last_purchase > 180
ORDER BY days_since_last_purchase DESC;

-- repeat purchase rate
SELECT 
    COUNT(CASE WHEN order_count > 1 THEN 1 END) AS repeat_customers,
    COUNT(*) AS total_customers_who_ordered,
    ROUND((COUNT(CASE WHEN order_count > 1 THEN 1 END) * 100.0 / COUNT(*)), 2) AS repeat_purchase_rate_pct
FROM (
    SELECT customer_id, COUNT(order_id) AS order_count
    FROM orders
    GROUP BY customer_id
) AS customer_order_counts;

-- high- value product feedback(sentiment vs sales)
SELECT 
    p.product_name,
    p.category,
    p.price,
    AVG(f.rating) AS avg_rating,
    COUNT(f.feedback_id) AS review_volume
FROM
    products p
        JOIN
    customer_feedback f ON p.product_id = f.product_id
GROUP BY p.product_id , p.product_name , p.category , p.price
HAVING avg_rating < 3.0
ORDER BY p.price DESC;

-- identifying the top 20% of customers(the pareto principle)
WITH CustomerRevenue AS (
    SELECT 
        customer_id, 
        SUM(order_amount) AS total_spent
    FROM orders
    WHERE order_status = 'Delivered'
    GROUP BY customer_id
),
RankedCustomers AS (
    SELECT 
        cr.customer_id,
        cr.total_spent,
        NTILE(5) OVER (ORDER BY cr.total_spent DESC) AS revenue_tile
    FROM CustomerRevenue cr
)
SELECT 
    rc.customer_id,
    c.name,
    rc.total_spent
FROM RankedCustomers rc
JOIN customers c ON rc.customer_id = c.customer_id
WHERE rc.revenue_tile = 1
ORDER BY rc.total_spent DESC;

-- demographic influence (age,gender & location)
SELECT 
    CASE 
        WHEN age < 25 THEN 'Under 25'
        WHEN age BETWEEN 25 AND 40 THEN '25-40'
        WHEN age BETWEEN 41 AND 60 THEN '41-60'
        ELSE '60+' 
    END AS age_group,
    gender,
    location,
    COUNT(o.order_id) AS total_orders,
    SUM(o.order_amount) AS total_revenue,
    ROUND(AVG(o.order_amount), 2) AS avg_spent_per_order
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
GROUP BY age_group, gender, location
ORDER BY total_revenue DESC;

-- repeat purchase rate by segment
WITH CustomerOrderCounts AS (
    SELECT 
        customer_id, 
        COUNT(order_id) AS order_count
    FROM orders
    GROUP BY customer_id
)
SELECT 
    c.customer_segment,
    COUNT(coc.customer_id) AS total_customers_in_segment,
    SUM(CASE WHEN coc.order_count > 1 THEN 1 ELSE 0 END) AS repeat_customer_count,
    ROUND(
        (SUM(CASE WHEN coc.order_count > 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(coc.customer_id)), 
        2
    ) AS repeat_rate_percentage
FROM customers c
LEFT JOIN CustomerOrderCounts coc ON c.customer_id = coc.customer_id
GROUP BY c.customer_segment
ORDER BY repeat_rate_percentage DESC;

-- monthly and quaterly sales trends
SELECT 
    DATE_FORMAT(order_date, '%Y-%m') AS order_month,
    CONCAT(YEAR(order_date), '-Q', QUARTER(order_date)) AS order_quarter,
    COUNT(order_id) AS total_orders,
    SUM(order_amount) AS total_revenue
FROM orders
WHERE order_status = 'Delivered'
GROUP BY order_month, order_quarter
ORDER BY order_month;

-- revenue by product category
SELECT 
    p.category,
    p.product_name,
    COUNT(DISTINCT o.order_id) AS unique_orders,
    SUM(o.order_amount) AS attributed_revenue
FROM products p
JOIN customer_feedback f ON p.product_id = f.product_id
JOIN orders o ON f.customer_id = o.customer_id
WHERE o.order_status = 'Delivered'
GROUP BY p.category, p.product_name
ORDER BY attributed_revenue DESC;

-- seasonal spikes and drops
SELECT 
    MONTHNAME(order_date) AS month_name,
    MONTH(order_date) AS month_num,
    ROUND(AVG(order_amount), 2) AS avg_daily_revenue,
    SUM(order_amount) AS total_monthly_revenue
FROM orders
WHERE order_status = 'Delivered'
GROUP BY month_name, month_num
ORDER BY month_num;

-- campaigns with the highest conversion rate
SELECT 
    campaign_name,
    channel,
    clicks,
    conversions,
    ROUND((conversions * 1.0 / NULLIF(clicks, 0)) * 100, 2) AS conversion_rate_pct
FROM marketing_campaigns
ORDER BY conversion_rate_pct DESC;

-- channel impact on conversions
SELECT 
    channel,
    COUNT(campaign_id) AS total_campaigns,
    SUM(budget) AS total_investment,
    SUM(conversions) AS total_conversions,
    ROUND(AVG((conversions * 1.0 / NULLIF(clicks, 0)) * 100), 2) AS avg_channel_cr_pct,
    ROUND(SUM(budget) / SUM(conversions), 2) AS cost_per_conversion
FROM marketing_campaigns
GROUP BY channel
ORDER BY total_conversions DESC;

-- budget vs. conversions (correlation analysis)
SELECT 
    campaign_name,
    budget,
    conversions,
    clicks,
    -- Efficiency metric: How many conversions do we get for every $100 spent?
    ROUND((conversions / budget) * 100, 2) AS conversions_per_100_dollars
FROM marketing_campaigns
ORDER BY budget DESC;

-- highest revenue products (attributed revenue)
SELECT 
    p.product_id,
    p.product_name,
    p.category,
    SUM(o.order_amount) AS total_attributed_revenue,
    COUNT(DISTINCT o.order_id) AS total_orders
FROM products p
JOIN customer_feedback f ON p.product_id = f.product_id
JOIN orders o ON f.customer_id = o.customer_id
WHERE o.order_status = 'Delivered'
GROUP BY p.product_id, p.product_name, p.category
ORDER BY total_attributed_revenue DESC
LIMIT 10;

-- Inventory Insights (Stock Status)
SELECT 
    product_name,
    category,
    inventory_count,
    price,
    CASE 
        WHEN inventory_count < 50 THEN 'Critical: Understocked'
        WHEN inventory_count BETWEEN 50 AND 150 THEN 'Low Stock'
        WHEN inventory_count > 400 THEN 'Overstocked'
        ELSE 'Healthy'
    END AS stock_status
FROM products
ORDER BY inventory_count ASC;

-- Return Patterns & Product Quality
SELECT 
    p.product_name,
    p.category,
    COUNT(CASE WHEN o.order_status = 'Returned' THEN 1 END) AS return_count,
    COUNT(o.order_id) AS total_order_mentions,
    ROUND((COUNT(CASE WHEN o.order_status = 'Returned' THEN 1 END) * 100.0 / COUNT(o.order_id)), 2) AS return_rate_pct,
    ROUND(AVG(f.rating), 1) AS avg_customer_rating
FROM products p
JOIN customer_feedback f ON p.product_id = f.product_id
JOIN orders o ON f.customer_id = o.customer_id
GROUP BY p.product_id, p.product_name, p.category
HAVING total_order_mentions > 5 -- Filters for products with enough data to be significant
ORDER BY return_rate_pct DESC;

-- Product Ratings (Top vs. Bottom Performers)
SELECT 
    p.product_name,
    p.category,
    ROUND(AVG(f.rating), 2) AS average_rating,
    COUNT(f.feedback_id) AS total_reviews
FROM products p
JOIN customer_feedback f ON p.product_id = f.product_id
GROUP BY p.product_id, p.product_name, p.category
-- We filter for products with at least 5 reviews to avoid outliers
HAVING total_reviews >= 5
ORDER BY average_rating DESC;

-- Feedback Patterns by Segment & Location
SELECT 
    c.customer_segment,
    c.location,
    ROUND(AVG(f.rating), 2) AS segment_avg_rating,
    COUNT(f.feedback_id) AS review_count
FROM customers c
JOIN customer_feedback f ON c.customer_id = f.customer_id
GROUP BY c.customer_segment, c.location
ORDER BY segment_avg_rating DESC;

-- "Quick & Dirty" Sentiment Keyword Analysis
SELECT 
    CASE 
        WHEN review LIKE '%great%' OR review LIKE '%excellent%' OR review LIKE '%love%' THEN 'Positive'
        WHEN review LIKE '%bad%' OR review LIKE '%poor%' OR review LIKE '%disappointed%' THEN 'Negative'
        WHEN review LIKE '%slow%' OR review LIKE '%delay%' THEN 'Shipping Issue'
        ELSE 'Neutral/Other'
    END AS review_sentiment,
    COUNT(*) AS review_count,
    ROUND(AVG(rating), 2) AS avg_rating_for_keyword
FROM customer_feedback
GROUP BY review_sentiment
ORDER BY review_count DESC;



