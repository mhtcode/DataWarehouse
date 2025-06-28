CREATE TABLE [DW].[AirlineAndAirport_Factless] (
  [AirlineID] int,
  [AirportID] int
)
GO

CREATE NONCLUSTERED INDEX IX_AirlineAndAirport_Factless_AirlineID
ON [DW].[AirlineAndAirport_Factless] (AirlineID);
GO

CREATE NONCLUSTERED INDEX IX_AirlineAndAirport_Factless_AirportID
ON [DW].[AirlineAndAirport_Factless] (AirportID);
GO