CREATE TABLE [DimAirline] (
  [AirlineKey] int PRIMARY KEY,
  [Name] nvarchar(255),
  [Country] nvarchar(255),
  [FoundedYear] int,
  [FleetSize] int,
  [Website] nvarchar(255),
  [EffectiveFrom] datetime,
  [EffectiveTo] datetime,
  [FleetSizeIsCurrent] bit
)
GO
