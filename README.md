
# ![Apple Logo](https://images.unsplash.com/photo-1615725802642-936d9aade2ba?q=80&w=1932&auto=format&fit=crop&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D) Apple Retail Sales Analysis - An Advanced SQL Project Analyzing Millions of Sales Rows

**Table Of Contents:**
- 1. [Project Overview](#1-project-overview)
- 2. [Entity Relationship Diagram (ERD)](#2-entity-relationship-diagram-erd)
- 3. [Database Schema](#3-database-schema)
- 4. [Key Business Problems Solved](#4-key-business-problems-solved)
- 5. [Query Optimization](#5-query-optimization)
- 6. [Skills Highlighted](#6-skills-highlighted)
- 7. [Dataset](#7-dataset)
- 8. [Conclusion](#8-conclusion)

## Project Overview

This project is designed to showcase advanced SQL querying techniques through the analysis of over 1 million rows of Apple retail sales data. The dataset includes information about products, stores, sales transactions, and warranty claims across various Apple retail locations globally. This project demonstrates advanced SQL querying techniques on a dataset of over 1 million rows from Apple retail sales. It showcases a wide range of analytical and problem-solving skills, including optimizing query performance, solving real-world business problems, and extracting actionable insights from large datasets.


## Entity Relationship Diagram (ERD)

![ERD](https://github.com/najirh/Apple-Retail-Sales-SQL-Project---Analyzing-Millions-of-Sales-Rows/blob/main/erd.png)

This Entity Relationship Diagram (ERD) represents a retail sales database (AppleDB) with five key tables:
1. Category: Stores product categories with category_id (Primary Key) and category_name.
2. Products: Contains product details, including product_id (Primary Key), product_name, category_id (Foreign Key to Category), launch_date, and price.
3. Sales: Records sales transactions with sale_id (Primary Key), sale_date, store_id (Foreign Key to Stores), product_id (Foreign Key to Products), and quantity.
4. Stores: Holds store-related details with store_id (Primary Key), store_name, city, and country.
5. Warranty: Tracks warranty claims with claim_id (Primary Key), claim_date, sale_id (Foreign Key to Sales), and repair_status.



## Database Schema

The project uses five main tables:

1. **stores**: Contains information about Apple retail stores.
   - `store_id`: Unique identifier for each store.
   - `store_name`: Name of the store.
   - `city`: City where the store is located.
   - `country`: Country of the store.

2. **category**: Holds product category information.
   - `category_id`: Unique identifier for each product category.
   - `category_name`: Name of the category.

3. **products**: Details about Apple products.
   - `product_id`: Unique identifier for each product.
   - `product_name`: Name of the product.
   - `category_id`: References the category table.
   - `launch_date`: Date when the product was launched.
   - `price`: Price of the product.

4. **sales**: Stores sales transactions.
   - `sale_id`: Unique identifier for each sale.
   - `sale_date`: Date of the sale.
   - `store_id`: References the store table.
   - `product_id`: References the product table.
   - `quantity`: Number of units sold.

5. **warranty**: Contains information about warranty claims.
   - `claim_id`: Unique identifier for each warranty claim.
   - `claim_date`: Date the claim was made.
   - `sale_id`: References the sales table.
   - `repair_status`: Status of the warranty claim (e.g., Paid Repaired, Warranty Void).

## Key Business Problems Solved

The project is split into three tiers of business questions of increasing complexity with a sample code snippet in each tier:

### Easy to Medium (10 Questions)

1. Find the number of stores in each country.
2. Calculate the total number of units sold by each store.
3. Identify how many sales occurred in December 2023.
4. Determine how many stores have never had a warranty claim filed.
5. Calculate the percentage of warranty claims marked as "Warranty Void".
6. Identify which store had the highest total units sold in the last year.
7. Count the number of unique products sold in the last year.
8. Find the average price of products in each category.
9. How many warranty claims were filed in 2020?
```sql
   SELECT 		c.category_name, ROUND(AVG(p.price)::NUMERIC, 2) AS avg_price
   FROM 		products p INNER JOIN category c
			ON p.category_id = c.category_id
   GROUP BY	        c.category_name
   ORDER BY	        avg_price DESC;
```
11. For each store, identify the best-selling day based on highest quantity sold.

### Medium to Hard (5 Questions)

11. Identify the least selling product in each country for each year based on total units sold.
```sql
WITH product_rank AS (
SELECT 	st.country, 
	p.product_name, 
	EXTRACT(YEAR FROM s.sale_date) AS year, 
	SUM(s.quantity) as total_units_sold,
	RANK() OVER(PARTITION BY st.country, EXTRACT(YEAR FROM s.sale_date) ORDER BY SUM(s.quantity) ASC) AS rank
FROM	sales s INNER JOIN stores st
			ON s.store_id = st.store_id
		INNER JOIN products p
			ON s.product_id = p.product_id
GROUP BY 1, 2, 3
)


SELECT 	country, year, product_name AS least_selling_product, total_units_sold
FROM	product_rank
WHERE 	rank = 1;
```
13. Calculate how many warranty claims were filed within 180 days of a product sale.
14. Determine how many warranty claims were filed for products launched in the last two years.
15. List the months in the last three years where sales exceeded 5,000 units in the USA.
16. Identify the product category with the most warranty claims filed in the last two years.

### Complex (5 Questions)

16. Determine the percentage chance of receiving warranty claims after each purchase for each country.
17. Analyze the year-by-year growth ratio for each store.
```sql
WITH sales_by_stores AS (
SELECT 		s.store_id, 
		st.store_name,
		EXTRACT(YEAR FROM s.sale_date) as year,
		SUM(s.quantity * p.price) AS total_sales_amount,
		LAG(SUM(s.quantity * p.price)) OVER(PARTITION BY s.store_id ORDER BY EXTRACT(YEAR FROM s.sale_date)) as prev_year_sales
FROM		sales s INNER JOIN stores st
				ON s.store_id = st.store_id
			INNER JOIN products p
				ON s.product_id = p.product_id
GROUP BY 	1, 2, 3
)
SELECT 	store_id, store_name, year, total_sales_amount,
		COALESCE(ROUND(((total_sales_amount - prev_year_sales)*100.0/prev_year_sales)::NUMERIC, 2), 0)AS year_by_year_growth_ratio
FROM 	sales_by_stores;
```
19. Calculate the correlation between product price and warranty claims for products sold in the last five years, segmented by price range.
20. Identify the store with the highest percentage of "Paid Repaired" claims relative to total claims filed.
21. Write a query to calculate the monthly running total of sales for each store over the past four years and compare trends during this period.

## Query Optimization
When working with large datasets, query performance becomes a key concern. As data grows, even simple queries can become slow and resource-intensive if not optimized properly. In this project, I implemented indexing strategies to improve query speed, especially on frequently queried columns like product_id, store_id, and sale_date.

Here’s how indexing helped improve performance:
Example: Filtering on product_id
--Without Index:
```sql
EXPLAIN ANALYSE
SELECT 	* 
FROM 	sales
WHERE	product_id = 'P-77';
```
Execution Time: ~75.853 ms

The query performed a full table scan, checking every row for a match.

--WITH INDEX:
```sql
CREATE INDEX sales_product_id ON sales(product_id);
```
Execution Time: ~4–8 ms

The query used the index to directly locate relevant rows, drastically reducing lookup time.


In short, query optimization—especially using indexes—is essential for building high-performance, scalable data systems, and this project helped me put those principles into practice.

## Skills Highlighted

This project primarily focuses on developing and showcasing the following SQL skills:

- **Complex Joins and Aggregations**: Demonstrating the ability to perform complex SQL joins and aggregate data meaningfully.
- **Window Functions**: Using advanced window functions for running totals, growth analysis, and time-based queries.
- **Data Segmentation**: Analyzing data across different time frames to gain insights into product performance.
- **Correlation Analysis**: Applying SQL functions to determine relationships between variables, such as product price and warranty claims.
- **Real-World Problem Solving**: Answering business-related questions that reflect real-world scenarios faced by data analysts.
- **Query Optimization**: Writing efficient SQL queries by reducing nested subqueries, minimizing data scans, and leveraging indexes and WITH clauses effectively for performance.


## Dataset

- **Size**: 1 million+ rows of sales data.
- **Period Covered**: The data spans multiple years, allowing for long-term trend analysis.
- **Geographical Coverage**: Sales data from Apple stores across various countries.

## Conclusion
	
Through this project, I’ve strengthened my SQL skills by solving real-world business problems using relational datasets. Working with multiple interconnected tables and thousands of records taught me how to write efficient and scalable queries that can handle large datasets without compromising performance. I learned to optimize queries using techniques like CTEs (WITH clauses), indexing strategies, and minimizing nested subqueries. This helped me process and analyze complex datasets more effectively. Overall, the project not only deepened my technical SQL knowledge but also sharpened my ability to think analytically and work with data at scale—key skills for any aspiring data analyst.

---
