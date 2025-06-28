CREATE TABLE [DW].[DimAircraft] (
  [AircraftKey] int PRIMARY KEY,
  [Model] nvarchar(255),
  [Type] nvarchar(255),
  [ManufacturerDate] date,
  [Capacity] int,
  [Price] decimal
)
GO


CREATE NONCLUSTERED INDEX IX_DimAircraft_Model
ON [DW].[DimAircraft] (Model);
GO

CREATE NONCLUSTERED INDEX IX_DimAircraft_Type
ON [DW].[DimAircraft] (Type);
GO

CREATE NONCLUSTERED INDEX IX_DimAircraft_ManufacturerDate
ON [DW].[DimAircraft] (ManufacturerDate);
GO
