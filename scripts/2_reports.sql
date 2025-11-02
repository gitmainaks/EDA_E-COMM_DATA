

/*
===============================================================================
Customer Report
===============================================================================
Purpose:
    - This report consolidates key customer metrics and behaviors

Highlights:
    1. Gathers essential fields such as CustomerID and transaction details.
	2. Segments customers into categories (VIP, Regular, New).
    3. Aggregates customer-level metrics:
	   - total orders
	   - total sales
	   - total quantity purchased
	   - total products
	   - lifespan (in months)
    4. Calculates valuable KPIs:
	    - recency (months since last order)
		- average order value
		- average monthly spend
===============================================================================
*/

if object_id('Customer_Report', 'v') is not null
	drop view Customer_Report;
go

create view Customer_Report as 

with base_query as(
/*------------------------------------------------
1) Base Query: Retrieves core columns from table
--------------------------------------------------*/
select 
InvoiceNo,
StockCode,
InvoiceDate,
SalesAmount,
Quantity,
CustomerID
from FactTableNew
where InvoiceDate is not null)

, customer_aggregation as (
/*---------------------------------------------------------------------
2) Customer Aggregations: Summarizes key metrics at the customer level
-----------------------------------------------------------------------*/
select
	CustomerID,
	count(distinct InvoiceNo) as total_orders,
	sum(SalesAmount) as total_sales,
	sum(Quantity) as total_quantity,
	count(distinct StockCode) as total_products,
	max(InvoiceDate) as last_order_date,
	datediff(month, min(InvoiceDate), max(InvoiceDate)) as lifespan
from base_query
group by CustomerID
)
select 
CustomerID,
case 
	when lifespan >= 3 and total_sales > 5000 then 'VIP'
	when lifespan >= 3 and total_sales <= 5000 then 'Regular'
	else 'New'
end as customer_segment,
last_order_date,
datediff(month, last_order_date, getdate()) as recency,
total_orders,
total_sales,
total_quantity,
total_products,
lifespan,
-- Computing average order value (AOV)
case when total_sales = 0 then  0
	 else total_sales / total_orders
end as avg_order_value,
-- Computing avg monthly spend
case when lifespan = 0 then total_sales
	 else total_sales / lifespan
end as avg_monthly_spend 
from customer_aggregation;



select * from Customer_Report;








/*
===============================================================================
Product Report
===============================================================================
Purpose:
    - This report consolidates key product metrics and behaviors.

Highlights:
    1. Gathers essential fields such as product name, price.
    2. Segments products by revenue to identify High-Performers, Mid-Range, or Low-Performers.
    3. Aggregates product-level metrics:
       - total orders
       - total sales
       - total quantity sold
       - total customers (unique)
       - lifespan (in months)
    4. Calculates valuable KPIs:
       - recency (months since last sale)
       - average order revenue (AOR)
       - average monthly revenue
===============================================================================
*/

if object_id('Product_Report', 'v') is not null
	drop view Product_Report;
go

create view Product_Report as

with base_query as (
/*-----------------------------------------------
1) Base Query: Retrieves core columns from table
-------------------------------------------------*/
	select 
		InvoiceNo,
		InvoiceDate,
		CustomerID,
		SalesAmount,
		Quantity,
		StockCode,
		ProductType,
		UnitPrice
	from FactTableNew
	where InvoiceDate is not null
),

product_aggregation as (
/*-------------------------------------------------------------------
2) Product Aggregations: Summarizes key metrics at the product level
---------------------------------------------------------------------*/
select 
	StockCode,
	ProductType,
	UnitPrice,
	datediff(month, min(InvoiceDate), max(InvoiceDate)) as lifespan,
	max(InvoiceDate) as last_sale_date,
	count(distinct InvoiceNo) as total_orders,
	count(distinct CustomerID) as total_customers,
	sum(SalesAmount) as total_sales,
	sum(Quantity) as total_quantity,
	round(avg(cast(SalesAmount as float) / nullif(Quantity, 0)), 1) as avg_selling_price
from base_query

group by 
	StockCode,
	ProductType,
	UnitPrice
)

/*-----------------------------------------------------------
3) Final Query: Combines all product results into one output
-------------------------------------------------------------*/
select 
	StockCode,
	ProductType,
	UnitPrice,
	last_sale_date,
	datediff(month, last_sale_date, getdate()) as recency_in_months,
	case
		when total_sales > 5000 then 'High-Performer'
		when total_sales >= 1000 then 'Mid-Range'
		else 'Low-Performer'
	end as product_segment,
	lifespan,
	total_orders,
	total_sales,
	total_quantity,
	total_customers,
	avg_selling_price,
	-- Average Order Revenue (AOR)
	case 
		when total_orders = 0 then 0
		else total_sales / total_orders
	end as avg_order_revenue,
	-- Average Monthly Revenue
	case 
		when lifespan = 0 then total_sales
		else total_sales / lifespan
	end as avg_monthly_revenue
from product_aggregation;



select * from Product_Report;


