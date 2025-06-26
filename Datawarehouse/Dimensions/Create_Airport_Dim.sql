CREATE TABLE [DW].[DimAirport] (
  [AirportID] INT PRIMARY KEY,
  [City] NVARCHAR(50),
  [Country] NVARCHAR(50),
  [IATACode] NVARCHAR(3),
  [ElevationMeter] INT,
  [TimeZone] NVARCHAR(50),
  [NumberOfTerminals] INT,
  [AnnualPassengerTraffic] BIGINT,
  [Latitude] DECIMAL(9,6),
  [Longitude] DECIMAL(9,6)
);
GO
