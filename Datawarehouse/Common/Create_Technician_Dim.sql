CREATE TABLE [DW].[DimTechnician] (
  [Technician_ID] integer PRIMARY KEY,
  [Name] nvarchar(255),
  [Certification_Level] nvarchar(255),
  [Employment_Type] nvarchar(255),
  [Active_Status] bit
)
GO
