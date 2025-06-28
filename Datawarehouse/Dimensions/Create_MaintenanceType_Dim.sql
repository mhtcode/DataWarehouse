CREATE TABLE [DW].[DimMaintenanceType] (
  [MaintenanceTypeID] integer PRIMARY KEY,
  [Name] nvarchar(255),
  [Category] nvarchar(255),
  [Description] nvarchar(255)
)
GO

CREATE NONCLUSTERED INDEX IX_DimMaintenanceType_Name
ON [DW].[DimMaintenanceType] (Name);
GO

CREATE NONCLUSTERED INDEX IX_DimMaintenanceType_Category
ON [DW].[DimMaintenanceType] (Category);
GO
