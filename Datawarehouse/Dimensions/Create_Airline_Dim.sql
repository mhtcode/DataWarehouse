CREATE TABLE [DW].[DimAirline] (
  [AirlineID] INT PRIMARY KEY,             -- Use AirlineID from SA (business key)
  [Name] NVARCHAR(100),
  [Country] NVARCHAR(50),
  [FoundedYear] INT,
  [FleetSize] INT,
  [Website] NVARCHAR(200),
  [Current_IATA_Code] VARCHAR(3) NULL,     -- Current code
  [Previous_IATA_Code] VARCHAR(3) NULL,    -- Type 3 SCD: previous value
  [IATA_Code_Changed_Date] DATE NULL       -- When change happened
);
GO
