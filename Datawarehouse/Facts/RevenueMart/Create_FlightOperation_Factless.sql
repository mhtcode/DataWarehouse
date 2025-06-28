CREATE TABLE [DW].[FlightOperation_Factless] (
  [FlightKey] int,
  [SourceAirportKey] int,
  [DestinationAirportKey] int,
  [AirlineKey] int,
  [AircraftKey] int,
  [OperationTypeKey] int
)
GO

CREATE NONCLUSTERED INDEX IX_FlightOperation_Factless_FlightKey
ON [DW].[FlightOperation_Factless] (FlightKey);
GO

CREATE NONCLUSTERED INDEX IX_FlightOperation_Factless_SourceAirportKey
ON [DW].[FlightOperation_Factless] (SourceAirportKey);
GO

CREATE NONCLUSTERED INDEX IX_FlightOperation_Factless_OperationTypeKey
ON [DW].[FlightOperation_Factless] (AircraftKey);
GO

CREATE NONCLUSTERED INDEX IX_FlightOperation_Factless_Route
ON [DW].[FlightOperation_Factless] (SourceAirportKey, DestinationAirportKey);
GO

CREATE NONCLUSTERED INDEX IX_FlightOperation_Factless_AirlineKey
ON [DW].[FlightOperation_Factless] (AirlineKey);
GO

CREATE NONCLUSTERED INDEX IX_FlightOperation_Factless_AircraftKey
ON [DW].[FlightOperation_Factless] (AircraftKey);
GO