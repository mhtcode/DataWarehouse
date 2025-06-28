CREATE TABLE [DW].[DimMaintenanceLocation] (
  [LocationKey] integer IDENTITY(1,1),
  [LocationID] nvarchar(100),
  [Name] nvarchar(255),
  [City] nvarchar(255),
  [Country] nvarchar(255),
  [Inhouse_Flag] bit,
  [EffectiveFrom] date,
  [EffectiveTo] date,
  [CityIsCurrent] bit
)
GO

CREATE NONCLUSTERED INDEX IX_DimMaintenanceLocation_BusinessKey_SCD
ON [DW].[DimMaintenanceLocation] ([LocationID], [EffectiveFrom], [EffectiveTo]);
GO

-- Index on Country and City
-- This composite index supports common geographic queries.
CREATE NONCLUSTERED INDEX IX_DimMaintenanceLocation_Country_City
ON [DW].[DimMaintenanceLocation] (Country, City);
GO

-- Index on Inhouse_Flag
-- Useful for quickly filtering locations based on whether they are in-house or external.
CREATE NONCLUSTERED INDEX IX_DimMaintenanceLocation_Inhouse_Flag
ON [DW].[DimMaintenanceLocation] (Inhouse_Flag);
GO

-- Index on Current Flag
-- A filtered index is highly efficient for queries that only need the current version of each location.
CREATE NONCLUSTERED INDEX IX_DimMaintenanceLocation_IsCurrent
ON [DW].[DimMaintenanceLocation] (CityIsCurrent)
WHERE CityIsCurrent = 1;
GO
