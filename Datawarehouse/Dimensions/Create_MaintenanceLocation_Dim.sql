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

CREATE NONCLUSTERED INDEX IX_DimMaintenanceLocation_Country_City
ON [DW].[DimMaintenanceLocation] (Country, City);
GO

CREATE NONCLUSTERED INDEX IX_DimMaintenanceLocation_Inhouse_Flag
ON [DW].[DimMaintenanceLocation] (Inhouse_Flag);
GO

CREATE NONCLUSTERED INDEX IX_DimMaintenanceLocation_IsCurrent
ON [DW].[DimMaintenanceLocation] (CityIsCurrent)
WHERE CityIsCurrent = 1;
GO
