CREATE TABLE [DW].[DimMaintenanceType] (
  [MaintenanceTypeID] integer PRIMARY KEY,
  [Name] nvarchar(500),
  [Category] nvarchar(500),
  [Description] nvarchar(500)
)
GO

CREATE NONCLUSTERED INDEX IX_DimMaintenanceType_Name
ON [DW].[DimMaintenanceType] (Name);
GO

CREATE NONCLUSTERED INDEX IX_DimMaintenanceType_Category
ON [DW].[DimMaintenanceType] (Category);
GO
