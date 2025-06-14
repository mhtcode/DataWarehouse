CREATE TABLE [DW].[DimServiceOffering] (
  [ServiceOfferingKey] int PRIMARY KEY,
  [Name] nvarchar(255),
  [TravelClass] nvarchar(255),
  [BaseCost] decimal,
  [PreviousBaseCost] decimal,
  [IncludesWiFi] bit,
  [IncludesMeal] bit,
  [BaggageAllowanceKg] int,
  [SeatType] nvarchar(255)
)
GO
