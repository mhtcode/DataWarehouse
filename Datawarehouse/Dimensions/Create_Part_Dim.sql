CREATE TABLE [DW].[DimPart] (
  [ID] integer PRIMARY KEY,
  [Name] nvarchar(255),
  [PartNumber] nvarchar(255),
  [Manufacturer] nvarchar(255),
  [Warranty_Period_Months] int,
  [Category] nvarchar(255)
)
GO


CREATE NONCLUSTERED INDEX IX_DimPart_PartNumber
ON [DW].[DimPart] (PartNumber);
GO

CREATE NONCLUSTERED INDEX IX_DimPart_Manufacturer
ON [DW].[DimPart] (Manufacturer);
GO

CREATE NONCLUSTERED INDEX IX_DimPart_Category
ON [DW].[DimPart] (Category);
GO
