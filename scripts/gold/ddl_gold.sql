/*
-------------------------------------------------------------------------------
DDL Script: Create Gold Views
-------------------------------------------------------------------------------
Script Purpose:
    This script is designed to create views for the Gold layer within the data warehouse. 
    The Gold layer consists of the final dimension and fact tables (Star Schema).
    
    Each view performs necessary transformations, aggregating and enriching data 
    from the Silver layer to generate a clean, enhanced dataset that is ready for business use.

Usage:
    - These views are intended for direct querying to support analytics and reporting activities.
-------------------------------------------------------------------------------
*/

-------------------------------------------------------------------------------
-- Create Dimension Table: gold.dim_customers
-------------------------------------------------------------------------------

IF OBJECT_ID('gold.dim_customers', 'V') IS NOT NULL
    DROP VIEW gold.dim_customers;
GO

CREATE VIEW gold.dim_customers AS
SELECT
  ROW_NUMBER() OVER(ORDER BY cst_id) AS customer_key, --surrogate key
  ci.cst_id AS customer_id,
  ci.cst_key AS customer_number,
  ci.cst_firstname AS first_name,
  ci.cst_lastname AS last_name,
  la.cntry AS country,
  ci.cst_marital_status AS marital_status,
  CASE 
    WHEN ci.cst_gndr != 'n/a' then ci.cst_gndr
	  ELSE COALESCE(ca.gen, 'n/a')
  END AS gender,ca.bdate AS birthday,
  ci.cst_create_date AS create_date
FROM silver.crm_cust_info ci
LEFT JOIN silver.erp_cust_az12 ca
  ON ci.cst_key = ca.cid
LEFT JOIN silver.erp_loc_a101 la
  ON ci.cst_key = la.cid;
GO

-- =============================================================================
-- Create Dimension Table: gold.dim_products
-- =============================================================================
IF OBJECT_ID('gold.dim_products', 'V') IS NOT NULL
    DROP VIEW gold.dim_products;
GO

CREATE VIEW gold.dim_products AS
SELECT
	ROW_NUMBER() OVER(ORDER BY pn.prd_start_dt, pn.prd_key) AS product_key,
	pn.prd_id AS product_id,
	pn.prd_key AS product_number,
	pn.prd_nm AS product_name,
	pn.cat_id AS category_id,
	pc.cat AS category,
	pc.subcat AS subcategory,
	pc.maintenance,
	pn.prd_nm,
	pn.prd_cost AS cost,
	pn.prd_line AS product_line,
	pn.prd_start_dt AS start_date
FROM silver.crm_prd_info pn
LEFT JOIN silver.erp_px_cat_g1v2 pc 
	ON pn.cat_id = pc.id
WHERE prd_end_dt IS NULL; -- Keep only active status, filter out historical
GO

-- =============================================================================
-- Create Fact Table: gold.fact_sales
-- =============================================================================
IF OBJECT_ID('gold.fact_sales', 'V') IS NOT NULL
    DROP VIEW gold.fact_sales;
GO

CREATE VIEW gold.fact_sales AS
SELECT 
  sd.sls_ord_num AS order_number,
  pr.product_key,  -- surrogate key from gold.dim_products
  cu.customer_key, -- surrogate key from gold.dim_customers
  sd.sls_order_dt AS order_date,
  sd.sls_ship_dt AS shipping_date,
  sd.sls_due_dt AS due_date,
  sd.sls_sales AS sales_amount,
  sd.sls_quantity AS quantity,
  sd.sls_price AS price
FROM silver.crm_sales_details sd
LEFT JOIN gold.dim_products pr
  ON sd.sls_prd_key = pr.product_number
LEFT JOIN gold.dim_customers cu
  ON sd.sls_cust_id = cu.customer_id;
GO
