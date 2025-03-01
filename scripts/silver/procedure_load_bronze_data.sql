/*
======================================================================================
Stored Procedure: Load Silver Layer (Clean, Transformed Tables from the Bronze Layer)
=======================================================================================
This stored procedure executes the ETL (Extract, Transform, Load) process to transfer 
and refine data from the Bronze schema (raw data) into the Silver schema (cleaned and 
structured data).

The procedure includes the following key steps:

	- Truncating existing Silver tables.
	- Inserting transformed and cleansed data from the Bronze Layer into the Silver Layer.

Command to perform the procedure:
	EXEC Silver.load_silver;
=======================================================================================
*/


--- Create stored procedure for silver layer ---
CREATE OR ALTER PROCEDURE silver.load_silver AS
BEGIN
	DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME;
	BEGIN TRY
		SET @batch_start_time = GETDATE();
		PRINT'*********************************************************************'
		PRINT'Loading Silver Layer'
		PRINT'*********************************************************************'

		PRINT'---------------------------------------------------------------------'
		PRINT'-----------------------Loading CRM Tables----------------------------'
		PRINT'---------------------------------------------------------------------'

		---Loading silver.crm_cust_info

		SET @start_time = GETDATE();
		PRINT'--- TRUNCATING TABLE silver.crm_cust_info ---';
		TRUNCATE TABLE silver.crm_cust_info;
		PRINT'--- INSERTING DATA INTO silver.crm_cust_info ---';
		INSERT INTO silver.crm_cust_info (
			cst_id, 
			cst_key, 
			cst_firstname, 
			cst_lastname, 
			cst_material_status, 
			cst_gndr, 
			cst_create_date
		)
		SELECT 
			cst_id,
			cst_key,
			TRIM(cst_firstname) AS cst_firstname, 
			TRIM(cst_lastname) AS cst_lastname,

			CASE WHEN UPPER(TRIM(cst_material_status)) = 'S' THEN 'Single'
				 WHEN UPPER(TRIM(cst_material_status)) = 'M' THEN 'Married'
				 ELSE 'n/a'
			END cst_material_status,

			CASE WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
				 WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
				 ELSE 'n/a'
			END cst_gndr,
			cst_create_date
		FROM
			(SELECT *,
			ROW_NUMBER() OVER(PARTITION BY cst_id ORDER BY cst_create_date DESC) as flag_last
			FROM bronze.crm_cust_info
			WHERE cst_id IS NOT NULL
			)t 
		WHERE flag_last=1;
		SET @end_time = GETDATE();
		PRINT'>>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds'
		PRINT'---------------------------------------------------------------------'

		---------------------------------------------------------------------------------------------------------------------------
		
		---Loading silver.crm_prd_info
		SET @start_time = GETDATE();
		PRINT'--- TRUNCATING TABLE silver.crm_prd_info ---';
		TRUNCATE TABLE silver.crm_prd_info;
		PRINT'--- INSERTING DATA INTO silver.crm_prd_info ---';
		INSERT INTO silver.crm_prd_info (
			prd_id,
			cat_id,
			prd_key,
			prd_nm,
			prd_cost,
			prd_line,
			prd_start_dt,
			prd_end_dt
		)
		SELECT 
			prd_id,
			REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id,    -- extract substr so it fits key from erp_px... table
			SUBSTRING(prd_key, 7, len(prd_key)) AS prd_key,		-- extract subst so it fits sales details table
			prd_nm,			-- was checked for extra spaces
			ISNULL(prd_cost, 0) AS prd_cost,	-- was checked for negatives, we had only IS NULL so replace with 0 

			CASE WHEN prd_line = 'R' THEN 'Road'
				 WHEN prd_line = 'M' THEN 'Mountain'
				 WHEN prd_line = 'S' THEN 'Other Sales'
				 WHEN prd_line = 'T' THEN 'Touring'
				 ELSE 'n/a'
			END AS prd_line,

			CAST(prd_start_dt AS DATE) AS prd_start_dt,  -- START DATE stays the same, end date is a date of next start date -1 day
			CAST(LEAD(prd_start_dt) OVER(PARTITION BY prd_key ORDER BY prd_start_dt)-1 AS DATE) AS prd_end_dt
		FROM bronze.crm_prd_info
		SET @end_time = GETDATE();
		PRINT'>>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds'
		PRINT'---------------------------------------------------------------------'

		------------------------------------------------------------------------------------------------------------------------------
		
		---Loading silver.crm_sales_details
		SET @start_time = GETDATE();
		PRINT'--- TRUNCATING TABLE silver.crm_sales_details ---';
		TRUNCATE TABLE silver.crm_sales_details;
		PRINT'--- INSERTING DATA INTO silver.crm_sales_details ---';
		INSERT INTO silver.crm_sales_details (
			sls_ord_num,
			sls_prd_key,
			sls_cust_id,
			sls_order_dt,
			sls_ship_dt,
			sls_due_dt,
			sls_sales,
			sls_quantity,
			sls_price
		)
		SELECT
			sls_ord_num,
			sls_prd_key,
			sls_cust_id,

			-- When changing the type for date in SQL server - first to varchar then to date
			CASE WHEN sls_order_dt = 0 OR LEN(sls_order_dt) != 8 THEN NULL
				 ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE)
			END AS sls_order_dt,

			CASE WHEN sls_ship_dt = 0 OR LEN(sls_ship_dt) != 8 THEN NULL
				 ELSE CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE)
			END AS sls_ship_dt,

			CASE WHEN sls_due_dt = 0 OR LEN(sls_due_dt) != 8 THEN NULL
				 ELSE CAST(CAST(sls_due_dt AS VARCHAR) AS DATE)
			END AS sls_due_dt,

			CASE WHEN sls_sales IS NULL OR sls_sales <= 0 OR sls_sales != sls_quantity * ABS(sls_price)
				THEN sls_quantity * ABS(sls_price)
			ELSE sls_sales
			END AS sls_sales,
			sls_quantity,
			CASE WHEN sls_price IS NULL OR sls_price <= 0
				THEN sls_sales / NULLIF(sls_quantity,0)
			ELSE sls_price
			END AS sls_price
		FROM bronze.crm_sales_details
		SET @end_time = GETDATE();
		PRINT'>>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds'

		------------------------------------------------------------------------------------------------------------------------------

		PRINT'---------------------------------------------------------------------'
		PRINT'-----------------------Loading CRM Tables----------------------------'
		PRINT'---------------------------------------------------------------------'

		---Loading silver.erp_cust_az12
		SET @start_time = GETDATE();
		PRINT'--- TRUNCATING TABLE silver.erp_cust_az12 ---';
		TRUNCATE TABLE silver.erp_cust_az12;
		PRINT'--- INSERTING DATA INTO silver.erp_cust_az12 ---';
		INSERT INTO silver.erp_cust_az12 (
			cid,
			bdate,
			gen)
		SELECT 
			--- Handling invalid values, adjusting cid to cst_key from customer table ---
			CASE WHEN cid like 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid))
				ELSE cid
			END AS cid,
			--- Handling invalid values from bdate ---
			CASE WHEN bdate > GETDATE() THEN NULL
				ELSE bdate
			END AS bdate,
			--- Data Normalization, mapping the code to more friendly value, ---
			--- handling missing values ---
			CASE WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female'
				WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Male'
				ELSE 'n/a'
			END AS gen
		FROM bronze.erp_cust_az12 
		SET @end_time = GETDATE();
		PRINT'>>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds'
		PRINT'---------------------------------------------------------------------'

		------------------------------------------------------------------------------------------------------------------------------
		
		---Loading silver.erp_cust_az12
		SET @start_time = GETDATE();
		PRINT'--- TRUNCATING TABLE silver.erp_loc_a101 ---';
		TRUNCATE TABLE silver.erp_loc_a101;
		PRINT'--- INSERTING DATA INTO silver.erp_cust_az12 ---';
		INSERT INTO silver.erp_loc_a101 (
		cid, 
		cntry
		)
		SELECT 
			--- Handle invalid values ---
			REPLACE(cid, '-', '') as cid, 
			--- Data Normalization and handling missing values ---
			CASE WHEN UPPER(TRIM(cntry)) IN ('DE', 'GERMANY') then 'Germany'
				 WHEN UPPER(TRIM(cntry)) IN ('USA','US', 'UNITED STATES') then 'United States'
				 WHEN UPPER(TRIM(cntry)) = 'UNITED KINGDOM' then 'United Kingdom'
				 WHEN UPPER(TRIM(cntry)) = 'AUSTRALIA' then 'Australia'
				 WHEN UPPER(TRIM(cntry)) = 'CANADA' then 'Canada'
				 WHEN UPPER(TRIM(cntry)) = 'FRANCE' then 'France'
				 WHEN TRIM(cntry)='' or cntry IS NULL then 'n/a'
				 END AS cntry
		FROM bronze.erp_loc_a101
		SET @end_time = GETDATE();
		PRINT'>>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds'
		PRINT'---------------------------------------------------------------------'

		------------------------------------------------------------------------------------------------------------------------------
		
		---Loading silver.erp_cust_az12
		SET @start_time = GETDATE();
		PRINT'--- TRUNCATING TABLE silver.erp_px_cat_g1v2 ---';
		TRUNCATE TABLE silver.erp_px_cat_g1v2;
		PRINT'--- INSERTING DATA INTO silver.erp_px_cat_g1v2 ---';
		INSERT INTO silver.erp_px_cat_g1v2 (
			id, 
			cat, 
			subcat, 
			maintenance
			)
		SELECT
			id,
			cat,
			subcat,
			maintenance
		FROM bronze.erp_px_cat_g1v2
		SET @end_time = GETDATE();
		PRINT'>>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds'
		PRINT'---------------------------------------------------------------------'

		SET @batch_end_time = GETDATE();
		PRINT'*********************************************************************'
		PRINT'Loading Silver Layer Completed'
		PRINT' >>> Total Load Duration: ' + CAST(DATEDIFF(SECOND, @batch_start_time, @batch_end_time) AS NVARCHAR)+ ' seconds'
		PRINT'*********************************************************************'
	END TRY
	BEGIN CATCH
		PRINT'====================================================================='
		PRINT'ERROR OCCURED DURING LOADING BRONZE LAYER'
		PRINT'Error Message' + ERROR_MESSAGE();
		PRINT'Error Message' + CAST(ERROR_NUMBER() AS NVARCHAR);
		PRINT'Error Message' + CAST(ERROR_STATE() AS NVARCHAR);
		PRINT'====================================================================='
	END CATCH
END
