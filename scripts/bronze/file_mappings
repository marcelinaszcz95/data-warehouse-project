CREATE TABLE bronze.file_mappings (
    id INT IDENTITY(1,1) PRIMARY KEY,  -- Auto-incrementing ID
    table_name NVARCHAR(255) NOT NULL, -- Name of the database table
    file_path NVARCHAR(500) NOT NULL   -- Path to the CSV file
);
GO

INSERT INTO bronze.file_mappings (table_name, file_path) VALUES
('bronze.crm_cust_info', 'C:\Downloads\datasets\source_crm\cust_info.csv'),
('bronze.crm_prd_info', 'C:\Downloads\datasets\source_crm\prd_info.csv'),
('bronze.crm_sales_details', 'C:\Downloads\datasets\source_crm\sales_details.csv'),
('bronze.erp_cust_az12', 'C:\Downloads\datasets\source_erp\CUST_AZ12.csv'),
('bronze.erp_loc_a101', 'C:\Downloads\datasets\source_erp\LOC_A101.csv'),
('bronze.erp_px_cat_g1v2', 'C:\Downloads\datasets\source_erp\PX_CAT_G1V2.csv');
