-- SQL script to create a single persistent temp table for DimPerson ETL

-- Persistent staging table used for both full and incremental loads
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

-- Usage:
-- TRUNCATE TABLE [DW].[Temp_Person_table] before each ETL run
-- Populate with source data via INSERT ... SELECT
-- Then use this table for both initial and incremental SCD2 loads.
