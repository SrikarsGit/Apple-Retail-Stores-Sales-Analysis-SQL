--Apple Retail Sales Project - Advanced SQL 

--View tables
SELECT * FROM category;
SELECT * FROM products;
SELECT * FROM stores;
SELECT * FROM sales;
SELECT * FROM warranty;

--Basic EDA
SELECT DISTINCT repair_status FROM warranty;

SELECT DISTINCT category_name FROM category;

SELECT COUNT(*) FROM sales; --1040200 rows in the sales table

--Improving Query Performance using Indexing strategy

--Execution Time Without Index On product_id - 75.853 ms
EXPLAIN ANALYSE
SELECT 	* 
FROM 	sales
WHERE	product_id = 'P-77';

CREATE INDEX sales_product_id ON sales(product_id);

--Execution Time With Index Index On product_id -  {4 - 8}ms
EXPLAIN ANALYSE
SELECT 	* 
FROM 	sales
WHERE	product_id = 'P-77';



--Execution Time Without Index On store_id - 76.980 ms

EXPLAIN ANALYSE
SELECT 	* 
FROM 	sales
WHERE	store_id = 'ST-55';

CREATE INDEX sales_store_id ON sales(store_id);

--Execution Time With Index On store_id -  {4 - 8} ms
EXPLAIN ANALYSE
SELECT 	* 
FROM 	sales
WHERE	store_id = 'ST-55';

--Finally let us create index on sale_date as well
CREATE INDEX sales_sale_date ON sales(sale_date);


--Business Problems

--1. Find the number of stores in each country.

SELECT		country, COUNT(store_id) AS num_stores
FROM		stores
GROUP BY	country
ORDER BY	num_stores DESC;

--2. Calculate the total number of units sold by each store.

SELECT		st.store_id, st.store_name, SUM(sa.quantity) as total_units_sold
FROM		sales sa INNER JOIN stores st 
			ON sa.store_id = st.store_id
GROUP BY	st.store_id, st.store_name
ORDER BY	total_units_sold DESC;

--3. Identify how many sales occurred in December 2023.

SELECT 	COUNT(sale_id) AS total_sales_in_dec2023 
FROM 	sales 
WHERE	EXTRACT(YEAR FROM sale_date) =  '2023' AND EXTRACT(MONTH FROM sale_date) = 12;

--or

SELECT 	COUNT(sale_id) AS total_sales_in_dec2023 
FROM 	sales 
WHERE	TO_CHAR(sale_date, 'MM-YYYY') = '12-2023';


--4. Determine how many stores have never had a warranty claim filed.

SELECT COUNT(*) FROM stores 
WHERE store_id NOT IN (
						SELECT 	DISTINCT s.store_id
						FROM 	warranty w LEFT JOIN sales s
								ON	w.sale_id = s.sale_id
						);
--5. Calcutate the percentage of warranty claims marked as "Rejected".

SELECT 	ROUND((SELECT COUNT(*) FROM warranty WHERE repair_status = 'Rejected')*100.0/COUNT(*), 2) AS rejected_pct
FROM 	warranty;

--6. Identify which store had the highest total units sold in the last year.

SELECT 		s.store_id, st.store_name, SUM(s.quantity) AS total_units_sold 
FROM 		sales s INNER JOIN stores st
			ON s.store_id = st.store_id
WHERE		sale_date >= CURRENT_DATE - INTERVAL '1 YEAR'
GROUP BY	s.store_id, st.store_name
ORDER BY 	total_units_sold DESC 

--7. Count the number of unique products sold in the last year.

SELECT 	COUNT(DISTINCT product_id) 
FROM	sales
WHERE	sale_date >= CURRENT_DATE - INTERVAL '1YEAR';

--8. Find the average price of products in each category.

SELECT 		c.category_name, ROUND(AVG(p.price)::NUMERIC, 2) AS avg_price
FROM 		products p INNER JOIN category c
			ON	p.category_id = c.category_id
GROUP BY	c.category_name
ORDER BY	avg_price DESC;

--9. How many warranty claims were filed in 2024?

SELECT 	COUNT(*) as warranty_claims_filed_in_2020 
FROM 	warranty
WHERE	DATE_PART('YEAR', claim_date) = 2024;

--10. For each store, identify the best-selling day based on highest quantity sold.

WITH ranked_quantity AS (
						 	SELECT		s.store_id, 
										st.store_name, 
										TO_CHAR(s.sale_date, 'Day') as Day, 
										SUM(quantity) AS total_quantity_sold,
										RANK() OVER(PARTITION BY s.store_id, st.store_name ORDER BY SUM(quantity) DESC) as quantity_sold_ranked
										
							FROM 		sales s INNER JOIN stores st
										ON	s.store_id = st.store_id
										
							GROUP BY	1, 2, 3
						)
SELECT	store_id, store_name, Day AS best_selling_day, total_quantity_sold
FROM	ranked_quantity
WHERE	quantity_sold_ranked = 1;

--11. Identify the least selling product in each country for each year based on total units sold.

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

--12. Calculate how many warranty claims were filed within 180 days of a product sale.

SELECT	COUNT(w.claim_date) AS warranty_claims_within_180_days
FROM 	warranty w LEFT JOIN sales s
		ON w.sale_id = s.sale_id
WHERE	claim_date - sale_date > 0 AND claim_date - sale_date <= 180;

--13. Determine how many warranty claims were filed for products launched in the last two years.

SELECT		p.product_name, COUNT(*) as num_warranty_claims
FROM		sales s INNER JOIN products p
						ON s.product_id = p.product_id
					RIGHT JOIN warranty w
						ON s.sale_id = w.sale_id
WHERE		p.launch_date >= CURRENT_DATE - INTERVAL '2 YEAR'
GROUP BY	p.product_name
ORDER BY	num_warranty_claims DESC;

--14. List the months in the last three years where sales exceeded 20,000 units in the USA.

SELECT 		TO_CHAR(s.sale_date, 'MM-YYYY') AS month, SUM(s.quantity) AS total_units
FROM 		sales s INNER JOIN stores st
			ON s.store_id = st.store_id
WHERE		st.country = 'United States'
			AND
			s.sale_date >= CURRENT_DATE - INTERVAL '3 YEARS'
GROUP BY 	month
HAVING		SUM(s.quantity) > 20000;

--15. Identify the product category with the most warranty claims filed in the last two years.

SELECT  	c.category_name, COUNT(w.claim_id) as warranty_claims
FROM 		warranty w LEFT JOIN sales s
							ON w.sale_id = s.sale_id
						INNER JOIN products p
							ON s.product_id = p.product_id
						INNER JOIN category c
							ON p.category_id = c.category_id	
WHERE		claim_date >= CURRENT_DATE - INTERVAL '2 YEARS'
GROUP BY	c.category_name	
ORDER BY	warranty_claims DESC;

--16. Determine the percentage chance of receiving warranty claims after each purchase for each country.

SELECT		st.country, 
			COUNT(w.claim_id) AS total_warranty_claims,
			SUM(s.quantity) AS total_quantity_sold,
			ROUND(COUNT(w.claim_id) * 100.0/SUM(s.quantity), 3) AS pct_chance_of_receiving_warranty_claims
			
FROM		sales s INNER JOIN stores st
						ON s.store_id = st.store_id
					LEFT JOIN warranty w
						ON s.sale_id = w.sale_id
GROUP BY	st.country
ORDER BY	pct_chance_of_receiving_warranty_claims DESC;

--17. Analyze the year-by-year growth ratio for each store.

WITH sales_by_stores AS (
							SELECT 		s.store_id, 
										st.store_name,
										EXTRACT(YEAR FROM s.sale_date) as year,
										SUM(s.quantity * p.price) AS total_sales_amount,
										LAG(SUM(s.quantity * p.price)) OVER(PARTITION BY s.store_id ORDER BY EXTRACT(YEAR FROM s.sale_date)) as prev_year_sales
										
							FROM		sales s INNER JOIN stores st
													ON s.store_id = st.store_id
												INNER JOIN	products p
													ON s.product_id = p.product_id
							GROUP BY 	1, 2, 3
						)
SELECT 	store_id, store_name, year, total_sales_amount,
		COALESCE(ROUND(((total_sales_amount - prev_year_sales)*100.0/prev_year_sales)::NUMERIC, 2), 0)AS year_by_year_growth_ratio
FROM 	sales_by_stores;

--18. Calculate the correlation between product price and warranty claims for products sold in the last five years, segmented by price range.

SELECT 		CASE 
				WHEN p.price < 500 THEN 'Less Expensive Product'
				WHEN p.price BETWEEN 500 AND 1000 THEN 'Mid Range Product'
				ELSE 'Expensive Product'
			END AS price_segment, 
			COUNT(w.claim_id) as total_warranty_claims
FROM		warranty w LEFT JOIN sales s
						ON w.sale_id = s.sale_id
					INNER JOIN products p
						ON s.product_id = p.product_id
GROUP BY	price_segment;

--19. Identify the store with the highest percentage of "Completed" claims relative to total claims filed

SELECT 		st.store_id, st.store_name,
			ROUND(SUM(CASE WHEN w.repair_status = 'Completed' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2)AS total_completed_claims_pct
FROM 		warranty w LEFT JOIN sales s
							ON w.sale_id = s.sale_id
						INNER JOIN stores st
							ON s.store_id = st.store_id
GROUP BY	st.store_id, st.store_name
ORDER BY 	total_completed_claims_pct DESC;

--20. Write a query to calculate the monthly running total of sales for each store over the past four years and compare trends during this period.

WITH monthly_sales_by_stores AS (
							SELECT		st.store_id, 
										st.store_name, 
										EXTRACT(YEAR FROM s.sale_date) AS year,
										EXTRACT(MONTH FROM s.sale_date) AS month,
										SUM(s.quantity * p.price) AS total_sales
							FROM		sales s INNER JOIN stores st
													ON s.store_id = st.store_id
												INNER JOIN products p
													ON p.product_id = s.product_id
							WHERE		s.sale_date >= CURRENT_DATE - INTERVAL '4 YEARS'
							GROUP BY	1, 2, 3, 4
					)

SELECT	store_id, store_name, year, month, total_sales,
		SUM(total_sales) OVER(PARTITION BY store_id, store_name, year ORDER BY month) AS running_sales_total
FROM 	monthly_sales_by_stores;


