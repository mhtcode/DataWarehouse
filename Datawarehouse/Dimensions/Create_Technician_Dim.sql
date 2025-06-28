CREATE TABLE [DW].[DimTechnician] (
  [Technician_ID] integer PRIMARY KEY,
  [PersonID] INT,
  [Specialty] NVARCHAR(100)
);
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
