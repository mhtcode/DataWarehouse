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
