CREATE TABLE [DW].[DimPart] (
  [ID] integer PRIMARY KEY,
  [Name] nvarchar(255),
  [PartNumber] nvarchar(255),
  [Manufacturer] nvarchar(255),
  [Warranty_Period_Months] int,
  [Category] nvarchar(255)
)
GO
