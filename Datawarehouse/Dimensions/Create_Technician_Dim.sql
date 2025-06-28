CREATE TABLE [DW].[DimTechnician] (
  [Technician_ID] integer PRIMARY KEY,
  [Name] nvarchar(255),
  [Certification_Level] nvarchar(255),
  [Employment_Type] nvarchar(255),
  [Active_Status] bit
)
GO

CREATE NONCLUSTERED INDEX IX_DimTechnician_Certification_Level
ON [DW].[DimTechnician] (Certification_Level);
GO

CREATE NONCLUSTERED INDEX IX_DimTechnician_Employment_Type
ON [DW].[DimTechnician] (Employment_Type);
GO

CREATE NONCLUSTERED INDEX IX_DimTechnician_Active_Status
ON [DW].[DimTechnician] (Active_Status)
WHERE Active_Status = 1;
GO
