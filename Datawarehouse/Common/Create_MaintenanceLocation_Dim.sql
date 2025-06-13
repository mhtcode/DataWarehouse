CREATE TABLE [DW].[DimMaintenanceLocation] (
  [Location_NK] nvarchar(255) UNIQUE,
  [Location_Surrogate_ID] integer PRIMARY KEY,
  [Name] nvarchar(255),
  [City] nvarchar(255),
  [Country] nvarchar(255),
  [Inhouse_Flag] bit,
  [Effective_Date] date,
  [Expiry_Date] date,
  [IsCurrent] bit
)
GO
