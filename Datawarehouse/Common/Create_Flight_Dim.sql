CREATE TABLE [DW].[DimFlight] (
  [FlightKey] int PRIMARY KEY,
  [FlightNumber] nvarchar(255),
  [DepartureDateTime] datetime,
  [ArrivalDateTime] datetime,
  [FlightDurationMinutes] int
)
GO
