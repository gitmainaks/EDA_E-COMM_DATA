

-- Sample data check
SELECT TOP 10 
    InvoiceNo,
    StockCode,
    ProductType,
    Quantity,
    InvoiceDate,
    UnitPrice,
    CustomerID,
    Country,
	TransactionType,
	PriceType,
	OriginalQuantity,
	OriginalUnitPrice
FROM FactTableNew;

-- Summary statistics
SELECT 
    COUNT(*) as TotalRows,
    MIN(Quantity) as MinQuantity,
    MAX(Quantity) as MaxQuantity,
    MIN(UnitPrice) as MinPrice,
    MAX(UnitPrice) as MaxPrice,
    MIN(InvoiceDate) as FirstDate,
    MAX(InvoiceDate) as LastDate
FROM FactTableNew;


SELECT 
    MIN(Quantity) as MinQuantity,
    MAX(Quantity) as MaxQuantity,
    MIN(UnitPrice) as MinPrice,
    MAX(UnitPrice) as MaxPrice,
	MIN(OriginalQuantity) as MinQuantity,
    MAX(OriginalQuantity) as MaxQuantity,
    MIN(OriginalUnitPrice) as MinPrice,
    MAX(OriginalUnitPrice) as MaxPrice
FROM FactTableNew;


select * from FactTableNew









/*======================================================
------------------------EDA-----------------------------
========================================================*/



/*
===============================================================================
Dimensions Exploration
===============================================================================
Purpose:
    - To explore the structure of dimension tables.
	
SQL Functions Used:
    - DISTINCT
    - ORDER BY
===============================================================================
*/


-- Retrieving a list of unique countries from which customers originate
select distinct 
	Country
from FactTableNew
order by Country;


-- Retrieving a list of unique StockCode and ProductType
select distinct 
	StockCode,
	ProductType
from FactTableNew 
order by StockCode, ProductType;

select distinct ProductType from FactTable 

/*
===============================================================================
Date Range Exploration 
===============================================================================
Purpose:
    - To determine the temporal boundaries of key data points.
    - To understand the range of historical data.

SQL Functions Used:
    - MIN(), MAX(), DATEDIFF()
===============================================================================
*/



-- Determining the first and last InvoiceDate and the total duration in months
SELECT 
    MIN(InvoiceDate) AS first_invoive_date,
    MAX(InvoiceDate) AS last_invoice_date,
    DATEDIFF(MONTH, MIN(InvoiceDate), MAX(InvoiceDate)) AS invoice_range_months
FROM FactTableNew;





/*========================================================================= 
Creating a new column as SalesAmount by multiplying Quantity and UnitPrice.
===========================================================================*/


-- Adding computed column that automatically calculates Sales
ALTER TABLE FactTableNew 
ADD SalesAmount AS (Quantity * UnitPrice);





/*
===============================================================================
Measures Exploration (Key Metrics)
===============================================================================
Purpose:
    - To calculate aggregated metrics (e.g., totals, averages) for quick insights.
    - To identify overall trends or spot anomalies.

SQL Functions Used:
    - COUNT(), SUM(), AVG()
===============================================================================
*/



-- Checking total sales
SELECT SUM(SalesAmount) AS TotalSales
FROM FactTableNew;

-- Checking sales by country
SELECT 
    Country,
    SUM(SalesAmount) AS TotalSales,
    COUNT(*) AS TransactionCount
FROM FactTableNew
GROUP BY Country
ORDER BY TotalSales DESC;

-- Checking sales by transaction type
SELECT 
    TransactionType,
    SUM(SalesAmount) AS TotalSales
FROM FactTableNew
GROUP BY TransactionType;

-- Sales by Product
select 
ProductType,
Quantity,
UnitPrice,
SalesAmount
from FactTableNew;




-- Finding how many items are sold
SELECT SUM(Quantity) AS TotalQuantity FROM FactTableNew;


-- Finding the average price of products
SELECT AVG(UnitPrice) AS AvgPrice FROM FactTableNew;



-- Finding the Total number of Orders
SELECT COUNT(InvoiceNo) AS total_orders FROM FactTableNew;
SELECT COUNT(DISTINCT InvoiceNo) AS total_orders FROM FactTableNew;


-- Finding the total number of products
SELECT COUNT(ProductType) AS total_products FROM FactTableNew;
SELECT COUNT(DISTINCT ProductType) AS total_products FROM FactTableNew;

-- Finding the total number of customers
SELECT COUNT(CustomerID) AS total_customers FROM FactTableNew;
-- Finding the total number of customers that has placed atleast an order
SELECT COUNT(DISTINCT CustomerID) AS total_customers FROM FactTableNew;





-- Generating a Report that shows all key metrics of the business
SELECT 'Total Sales' AS Measure_Name, SUM(SalesAmount) AS Measure_Value FROM FactTableNew
UNION ALL
SELECT 'Total Quantity', SUM(Quantity) FROM FactTableNew
UNION ALL
SELECT 'Average Price', AVG(UnitPrice) FROM FactTableNew
UNION ALL
SELECT 'Total Orders', COUNT(DISTINCT InvoiceNo) FROM FactTableNew
UNION All
SELECT 'Total Products', COUNT(DISTINCT ProductType) FROM FactTableNew
UNION ALL
SELECT 'Total Customers', COUNT(CustomerID) FROM FactTableNew;







-- Cross Checking things...
select
OriginalQuantity,
TransactionType,
OriginalUnitPrice,
PriceType
from FactTableNew;

select 
TransactionType, 
PriceType
from FactTableNew
where TransactionType = 'Return' or PriceType ='Refund';







/*
===============================================================================
Magnitude Analysis
===============================================================================
Purpose:
    - To quantify data and group results by specific dimensions.
    - For understanding data distribution across categories.

SQL Functions Used:
    - Aggregate Functions: SUM(), COUNT(), AVG()
    - GROUP BY, ORDER BY
===============================================================================
*/



-- Finding total customers by countries
SELECT
    Country,
    COUNT(CustomerID) AS total_customers
FROM FactTableNew
GROUP BY Country
ORDER BY total_customers DESC;


-- Finding total customers by product type
SELECT
    ProductType,
    COUNT(CustomerID) AS total_customers
FROM FactTableNew
GROUP BY ProductType
ORDER BY total_customers DESC;


-- Finding total sales by product
SELECT 
	ProductType,
	SUM(SalesAmount) AS total_sales
FROM FactTableNew
GROUP BY ProductType
ORDER BY total_sales DESC;


-- Avg sales of each product
SELECT 
	ProductType,
	AVG(SalesAmount) AS avg_sales
FROM FactTableNew
GROUP BY ProductType
ORDER BY avg_sales DESC;


-- Total sales generated by each customer
SELECT 
	CustomerID,
	SUM(SalesAmount) AS total_sales
FROM FactTableNew
GROUP BY CustomerID
ORDER BY total_sales DESC; -- need to clean CustomerID (invalid & null)


-- The distribution of sold items across countries
SELECT
	Country,
	SUM(OriginalQuantity) as total_sold_items
FROM FactTableNew
WHERE OriginalQuantity > 0
GROUP BY Country
ORDER BY total_sold_items DESC;





/*
===============================================================================
Ranking Analysis
===============================================================================
Purpose:
    - To rank items (e.g., products, customers) based on performance or other metrics.
    - To identify top performers or laggards.

SQL Functions Used:
    - Window Ranking Functions: RANK(), TOP
    - Clauses: GROUP BY, ORDER BY
===============================================================================
*/


-- Which 5 products Generating the Highest Revenue?
-- Simple Ranking
select top 5
	ProductType,
	sum(SalesAmount) as total_revenue
from FactTableNew
group by ProductType
order by total_revenue desc;

-- Complex but flexibly ranking using windows functions
select *
from(
	select 
		ProductType,
		sum(SalesAmount) as total_revenue,
		rank() over(order by sum(SalesAmount) desc) as rank_products
	from FactTableNew
	group by ProductType
) as ranked_products
where rank_products <= 5; 


-- What are the 5 worst-performing products in terms of sales?
select top 5
	ProductType,
	sum(SalesAmount) as total_revenue
from FactTableNew
group by ProductType
order by total_revenue;


-- Find the top 10 customers who have generated the highest revenue
select top 10 
	CustomerID,
	sum(SalesAmount) as total_revenue
from FactTableNew
group by CustomerID
order by total_revenue desc;


-- The 3 customers with the fewest orders placed
select top 3
	CustomerID,
	count(distinct InvoiceNo) as total_orders
from FactTableNew
group by CustomerID
order by total_orders; -- need to clean CustomerID





/*
===============================================================================
Change Over Time Analysis
===============================================================================
Purpose:
    - To track trends, growth, and changes in key metrics over time.
    - For time-series analysis and identifying seasonality.
    - To measure growth or decline over specific periods.

SQL Functions Used:
    - Date Functions: DATETRUNC(), FORMAT()
    - Aggregate Functions: SUM(), COUNT(),
===============================================================================
*/

-- Analyse sales performance over time
-- Quick Date Functions
select 
	year(InvoiceDate) as order_year,
	month(InvoiceDate) as order_month,
	sum(SalesAmount) as total_sales,
	count(distinct CustomerID) as total_customers,
	sum(Quantity) as total_quantity
from FactTableNew
where InvoiceDate is not null
group by year(InvoiceDate), month(InvoiceDate)
order by year(InvoiceDate), month(InvoiceDate);

-- DATETRUNC()
select 
	DATETRUNC(month, InvoiceDate) as order_date,
	sum(SalesAmount) as total_sales,
	count(distinct CustomerID) as total_customers,
	sum(Quantity) as total_quantity
from FactTableNew
where InvoiceDate is not null
group by DATETRUNC(month, InvoiceDate)
order by DATETRUNC(month, InvoiceDate);

-- FORMAT()
select 
	FORMAT(InvoiceDate, 'yyyy-MMM') as order_date,
	sum(SalesAmount) as total_sales,
	count(distinct CustomerID) as total_customers,
	sum(Quantity) as total_quantity
from FactTableNew
where InvoiceDate is not null
group by FORMAT(InvoiceDate, 'yyyy-MMM')
order by FORMAT(InvoiceDate, 'yyyy-MMM');  -- problem in the order of months!!?




/*
===============================================================================
Cumulative Analysis
===============================================================================
Purpose:
    - To calculate running totals or moving averages for key metrics.
    - To track performance over time cumulatively.
    - Useful for growth analysis or identifying long-term trends.

SQL Functions Used:
    - Window Functions: SUM() OVER(), AVG() OVER()
===============================================================================
*/

-- Calculate the total sales per month 
-- and the running total of sales over time 
select 
	InvoiceDate,
	total_sales,
	sum(total_sales) over (order by InvoiceDate) as running_total_sales,
	avg(total_sales) over (order by InvoiceDate) as moving_avg_sales
from
(
	select 
		DATETRUNC(month, InvoiceDate) as InvoiceDate,
		sum(SalesAmount) as total_sales,
		avg(SalesAmount) as avg_sales
	from FactTableNew
	where InvoiceDate is not null
	group by DATETRUNC(month, InvoiceDate)
)t






/*
===============================================================================
Performance Analysis (Month-over-Month)
===============================================================================
Purpose:
    - To measure the performance of products, customers, or regions over time.
    - For benchmarking and identifying high-performing entities.
    - To track yearly trends and growth.

SQL Functions Used:
    - LAG(): Accesses data from previous rows.
    - AVG() OVER(): Computes average values within partitions.
    - CASE: Defines conditional logic for trend analysis.
===============================================================================
*/

/* Analyze the monthly performance of products by comparing their sales 
to both the average sales performance of the product and the previous month's sales */
with montly_product_sales as (
	select 
		month(InvoiceDate) as order_month,
		ProductType,
		sum(SalesAmount) as current_sales
	from FactTableNew
	where InvoiceDate is not null
	group by 
		month(InvoiceDate),
		ProductType
)
select 
	order_month,
	ProductType,
	current_sales,
	avg(current_sales) over (partition by ProductType) as avg_sales,
	current_sales - avg(current_sales) over (partition by ProductType) as diff_avg,
	case 
		when current_sales - avg(current_sales) over (partition by ProductType) > 0 then 'Above Avg'
		when current_sales - avg(current_sales) over (partition by ProductType) < 0 then 'Below Avg'
		else 'Avg'
	end as avg_change,
	-- Month-over-Month Analysis
	lag(current_sales) over (partition by ProductType order by order_month) as pm_sales,
	current_sales - lag(current_sales) over (partition by ProductType order by order_month) as diff_pm,
	case 
		when current_sales - lag(current_sales) over (partition by ProductType order by order_month) > 0 then 'Increase'
		when current_sales - lag(current_sales) over (partition by ProductType order by order_month) < 0 then 'Decrease'
		else 'No Change'
	end as pm_change
from montly_product_sales
order by ProductType, order_month;






/*
===============================================================================
Part-to-Whole Analysis
===============================================================================
Purpose:
    - To compare performance or metrics across dimensions or time periods.
    - To evaluate differences between categories.
    - Useful for A/B testing or regional comparisons.

SQL Functions Used:
    - SUM(): Aggregates values for comparison.
    - Window Functions: SUM() OVER() for total calculations.
===============================================================================
*/
-- Which country contribute the most to overall sales?
with country_sales as (
	select 
		Country,
		sum(SalesAmount) as total_sales 
	from FactTableNew
	group by Country
)
select 
	Country,
	total_sales,
	sum(total_sales) over() as overall_sales,
	round(cast(total_sales as float) / sum(total_sales) over() * 100, 2) as percentage_of_total
from country_sales
order by total_sales desc;

-- Which product contribute the most to overall sales?
with product_sales as (
	select 
		ProductType,
		sum(SalesAmount) as total_sales 
	from FactTableNew
	group by ProductType
)
select 
	ProductType,
	total_sales,
	sum(total_sales) over() as overall_sales,
	round(cast(total_sales as float) / sum(total_sales) over() * 100, 2) as percentage_of_total
from product_sales
order by total_sales desc;






/*
===============================================================================
Data Segmentation Analysis
===============================================================================
Purpose:
    - To group data into meaningful categories for targeted insights.
    - For customer segmentation, product categorization, or regional analysis.

SQL Functions Used:
    - CASE: Defines custom segmentation logic.
    - GROUP BY: Groups data into segments.
===============================================================================
*/

/*Segment products into price ranges and 
count how many products fall into each segment*/
with product_segments as (
	select 
		StockCode,
		ProductType,
		UnitPrice,
		case 
			when UnitPrice < 100 then 'Below 100'
			when UnitPrice between 100 and 500 then '100-500'
			when UnitPrice between 500 and 1000 then '500-1000'
			else 'Above 1000'
		end as price_range
	from FactTableNew
)
select 
	price_range,
	count(StockCode) as total_products 
from product_segments
group by price_range
order by total_products desc;


/*Group customers into three segments based on their spending behavior:
	- VIP: Customers with at least 3 months of history and spending more than €5,000.
	- Regular: Customers with at least 3 months of history but spending €5,000 or less.
	- New: Customers with a lifespan less than 3 months.
And find the total number of customers by each group
*/
with customer_spending as (
	select 
		CustomerID,
		sum(SalesAmount) as total_spending,
		min(InvoiceDate) as first_order,
		max(InvoiceDate) as last_order,
		datediff(month, min(InvoiceDate), max(InvoiceDate)) as lifespan
	from FactTableNew
	group by CustomerID
)
select
	customer_segment,
	count(CustomerID) as total_customers
from ( 
	select 
		CustomerID,
		case 
			when lifespan >= 3 and total_spending > 5000 then 'VIP'
			when lifespan >= 3 and total_spending <= 5000 then 'Regular'
			else 'New'
		end as customer_segment
	from customer_spending
) as segmented_customers
group by customer_segment
order by total_customers desc;


