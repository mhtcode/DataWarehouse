CREATE TABLE [DimAircraft] (
  [AircraftKey] int PRIMARY KEY,
  [Model] nvarchar(255),
  [Type] nvarchar(255),
  [ManufacturerDate] date,
  [Capacity] int,
  [Price] decimal
)
GO
