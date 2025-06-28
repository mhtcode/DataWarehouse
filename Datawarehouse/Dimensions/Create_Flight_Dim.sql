CREATE TABLE [DW].[DimFlight] (
  [FlightDetailID]      INT PRIMARY KEY,        -- Business key from SA
  [DepartureAirportName] NVARCHAR(100),         -- From SA.Airport via DepartureAirportID
  [DestinationAirportName] NVARCHAR(100),       -- From SA.Airport via DestinationAirportID
  [DepartureDateTime]   DATETIME,
  [ArrivalDateTime]     DATETIME,
  [FlightDurationMinutes] INT,
  [AircraftName]        NVARCHAR(100),          -- From SA.Aircraft
  [FlightCapacity]      INT,
  [TotalCost]           DECIMAL(18,2)
);
GO

CREATE NONCLUSTERED INDEX IX_DimFlight_Route
ON [DW].[DimFlight] (DepartureAirportName, DestinationAirportName);
GO

CREATE NONCLUSTERED INDEX IX_DimFlight_AircraftName
ON [DW].[DimFlight] (AircraftName);
GO

CREATE NONCLUSTERED INDEX IX_DimFlight_DepartureDateTime
ON [DW].[DimFlight] (DepartureDateTime);
GO