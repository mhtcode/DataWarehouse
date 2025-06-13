CREATE TABLE [DimAirport] (
  [AirportKey] int PRIMARY KEY,
  [Name] nvarchar(255),
  [City] nvarchar(255),
  [Country] nvarchar(255),
  [IATACode] nvarchar(255),
  [ElevationMeter] int,
  [TimeZone] nvarchar(255),
  [NumberOfTerminals] int,
  [AnnualPassengerTraffic] bigint,
  [Latitude] decimal,
  [Longitude] decimal
)
GO
