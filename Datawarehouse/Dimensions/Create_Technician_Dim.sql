CREATE TABLE [DW].[DimTechnician] (
  [Technician_ID] integer PRIMARY KEY,
  [PersonID] INT,
  [Name] INT,
  [Phone] INT,
  [Specialty] NVARCHAR(100)
);
GO

CREATE NONCLUSTERED INDEX IX_DimTechnician_PersonID
ON [DW].[DimTechnician] (PersonID);
GO

CREATE NONCLUSTERED INDEX IX_DimTechnician_Specialty
ON [DW].[DimTechnician] (Specialty);
GO
