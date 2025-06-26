CREATE TABLE [DW].[DimAirline] (
  [AirlineKey] int PRIMARY KEY,
  [Name] nvarchar(255),
  [Country] nvarchar(255),
  [FoundedYear] int,
  [FleetSize] int,
  [Website] nvarchar(255),
  [Current_IATA_Code] varchar(3) NULL,
  [Previous_IATA_Code] varchar(3) NULL,
  [IATA_Code_Changed_Date] date NULL,
)
GO
