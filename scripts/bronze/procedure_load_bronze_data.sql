/*
=============================================================================
Stored Purpose: Load Bronze Layer (Source -> Bronze)
=============================================================================

Script purpose:
  This stored procedure loads the data into the bronze schema from external csv files.
  It performs the following actions:
    - Truncates the bronze tables before loading data.
    - Uses the 'BULK INSERT' command to load data from csv Files to bronze tables.

Parameters:
  None.
This stored procedure does not accept any parameters or return any values.

Usage example:
  EXEC bronze.load_bronze;
===============================================================================
*/


CREATE OR ALTER PROCEDURE bronze.load_bronze_data
AS
BEGIN
    DECLARE @table_name NVARCHAR(255), @file_path NVARCHAR(500);
    DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME;

    BEGIN TRY
        SET @batch_start_time = GETDATE();
        PRINT '=================== Starting Bronze Layer Load ===================';

        -- Cursor to loop through each table and its file path
        DECLARE table_cursor CURSOR FOR 
        SELECT table_name, file_path FROM bronze.file_mappings;

        OPEN table_cursor;
        FETCH NEXT FROM table_cursor INTO @table_name, @file_path;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            SET @start_time = GETDATE();
            PRINT '>> Processing Table: ' + @table_name;

            -- Truncate the table before inserting new data
            EXEC ('TRUNCATE TABLE ' + @table_name);

            -- Bulk insert data from CSV file
            EXEC ('
                BULK INSERT ' + @table_name + '
                FROM ''' + @file_path + '''
                WITH (
                    FIRSTROW = 2,
                    FIELDTERMINATOR = '','',
                    TABLOCK
                )'
            );

            SET @end_time = GETDATE();
            PRINT '>> Load Duration for ' + @table_name + ': ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';

            FETCH NEXT FROM table_cursor INTO @table_name, @file_path;
        END;

        CLOSE table_cursor;
        DEALLOCATE table_cursor;

        SET @batch_end_time = GETDATE();
        PRINT '=================== Bronze Layer Load Completed ===================';
        PRINT 'Total Duration: ' + CAST(DATEDIFF(second, @batch_start_time, @batch_end_time) AS NVARCHAR) + ' seconds';

    END TRY
    BEGIN CATCH
        PRINT '***** ERROR OCCURRED DURING LOADING *****';
        PRINT 'Error Message: ' + ERROR_MESSAGE();
        
        -- Log errors in an error log table
        INSERT INTO bronze.error_log (error_message, error_state, error_time)
        VALUES (ERROR_MESSAGE(), ERROR_STATE(), GETDATE());
    END CATCH
END;
