-- Persistent staging table used for both full and incremental loads
IF OBJECT_ID('[DW].[Temp_Person_table]', 'U') IS NULL
BEGIN
	CREATE TABLE [DW].[Temp_Person_table] (
	  [PersonID]       INT           NOT NULL PRIMARY KEY,
	  [NationalCode]   NVARCHAR(255) NULL,
	  [PassportNumber] NVARCHAR(255) NULL,
	  [Name]           NVARCHAR(255) NULL,
	  [Gender]         NVARCHAR(255) NULL,
	  [DateOfBirth]    DATE          NULL,
	  [City]           NVARCHAR(255) NULL,
	  [Country]        NVARCHAR(255) NULL,
	  [Email]          NVARCHAR(255) NULL,
	  [Phone]          NVARCHAR(255) NULL,
	  [Address]        NVARCHAR(255) NULL,
	  [PostalCode]     NVARCHAR(255) NULL
	);
	END;
GO
-- Usage:
-- TRUNCATE TABLE [DW].[Temp_Person_table] before each ETL run
-- Populate with source data via INSERT ... SELECT
-- Then use this table for both initial and incremental SCD2 loads.


IF OBJECT_ID('[DW].[Temp_Aircraft_table]', 'U') IS NULL
BEGIN
  CREATE TABLE [DW].[Temp_Aircraft_table] (
    [AircraftID]        INT           NOT NULL PRIMARY KEY,
    [Model]             NVARCHAR(255) NULL,
    [Type]              NVARCHAR(255) NULL,
    [ManufacturerDate]  DATE          NULL,
    [Capacity]          INT           NULL,
    [Price]             DECIMAL(18,2) NULL
  );
END;
GO