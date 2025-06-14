CREATE TABLE [DW].[DimFlight] (
  [FlightKey] int PRIMARY KEY,
  [DepartureDateTime] datetime,
  [ArrivalDateTime] datetime,
  [FlightDurationMinutes] int,
  [AircraftKey] int,
  [FlightCapacity] int,
  [TotalCost] int
)
GO
