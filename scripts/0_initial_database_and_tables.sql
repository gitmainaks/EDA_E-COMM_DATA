
use master;
go

-- Drop and recreate the 'DWEcommData' database
if exists (select 1 from sys.databases where name = 'DWEcommData') 
begin 
	alter database DWEcommData set single_user with rollback immediate;
	drop database DWEcommData;
end;
go 

-- Create the 'DWEcommData' database
create database DWEcommData;
go

use DWEcommData;
go




-- Create the Fact Table 
create table FactTable(
	InvoiceNo nvarchar(50),
	StockCode nvarchar(50),
	ProductType nvarchar(100),
	Quantity nvarchar(50),
	InvoiceDate nvarchar(100),
	UnitPrice nvarchar(50),
	CustomerID nvarchar(50),
	Country nvarchar(50)
);
go

truncate table FactTable;
go

bulk insert FactTable
from 'C:\Users\MAINAK AS\OneDrive\Desktop\E-Commerce Data\ecomm_data.csv'
with ( 
	firstrow = 2,
	fieldterminator = ',',
	tablock
);
go 


select * from FactTable


-- Create a new table with correct data types


-- Drop if exists and create new table
IF OBJECT_ID('FactTableNew', 'U') IS NOT NULL
    DROP TABLE FactTableNew;

CREATE TABLE FactTableNew (
    InvoiceNo VARCHAR(50),
    StockCode VARCHAR(50),
    ProductType VARCHAR(100),
    Quantity INT,
    InvoiceDate DATETIME,
    UnitPrice DECIMAL(10,2),
    CustomerID VARCHAR(50),
    Country VARCHAR(100),
    TransactionType VARCHAR(20),
    PriceType VARCHAR(20),
    OriginalQuantity INT,
    OriginalUnitPrice DECIMAL(10,2)
);




INSERT INTO FactTableNew(
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
)
SELECT 
    InvoiceNo,
    StockCode,
    ProductType,
    COALESCE(ABS(TRY_CAST(Quantity AS INT)), 0) AS Quantity,  -- Handle NULLs by setting to 0
    TRY_CAST(InvoiceDate AS DATETIME) AS InvoiceDate,
    COALESCE(ABS(TRY_CAST(UnitPrice AS DECIMAL(10,2))), 0.00) AS UnitPrice,
    CustomerID,
    -- Cleaning the Country column - take only the country part after the last comma
	CASE 
		WHEN CHARINDEX(',', Country) > 0 THEN 
			LTRIM(RTRIM(REVERSE(LEFT(REVERSE(Country), CHARINDEX(',', REVERSE(Country)) - 1))))
		ELSE Country
	END AS CleanedCountry,
    CASE 
        WHEN TRY_CAST(Quantity AS INT) < 0 THEN 'Return'   -- Business logic
        WHEN Quantity IS NULL THEN 'Missing'
        ELSE 'Sale' 
    END AS TransactionType,
    CASE 
        WHEN TRY_CAST(UnitPrice AS DECIMAL(10,2)) < 0 THEN 'Refund'   -- Business logic
        WHEN UnitPrice IS NULL THEN 'Missing'
        ELSE 'Normal' 
    END AS PriceType,
    TRY_CAST(Quantity AS INT) AS OriginalQuantity,
    TRY_CAST(UnitPrice AS DECIMAL(10,2)) AS OriginalUnitPrice
FROM FactTable
-- Only filter out records that are completely unusable
WHERE InvoiceNo IS NOT NULL;  -- Keeping everything that has at least an InvoiceNo






 -- Verify the data transfer
SELECT COUNT(*) as OriginalCount FROM FactTable;
SELECT COUNT(*) as NewCount FROM FactTableNew;





-- Check data types
SELECT 
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'FactTableNew';

