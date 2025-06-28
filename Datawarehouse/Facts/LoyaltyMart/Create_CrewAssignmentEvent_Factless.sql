CREATE TABLE [DW].[CrewAssignmentEvent_Factless] (
  [FlightID] INT,
  [SourceAirportID] INT,
  [DestinationAirportID] INT,
  [AircraftID] INT,
  [AirlineID] INT,
  [CrewID] INT
)
GO

CREATE NONCLUSTERED INDEX IX_CrewAssignmentEvent_Factless_FlightID
ON [DW].[CrewAssignmentEvent_Factless] (FlightID);
GO

CREATE NONCLUSTERED INDEX IX_CrewAssignmentEvent_Factless_SourceAirportID
ON [DW].[CrewAssignmentEvent_Factless] (SourceAirportID);
GO


CREATE NONCLUSTERED INDEX IX_CrewAssignmentEvent_Factless_DestinationAirportID
ON [DW].[CrewAssignmentEvent_Factless] (DestinationAirportID);
GO

CREATE NONCLUSTERED INDEX IX_CrewAssignmentEvent_Factless_CrewID
ON [DW].[CrewAssignmentEvent_Factless] (CrewID);
GO

CREATE NONCLUSTERED INDEX IX_CrewAssignmentEvent_Factless_AirlineID
ON [DW].[CrewAssignmentEvent_Factless] (AirlineID);
GO


CREATE NONCLUSTERED INDEX IX_CrewAssignmentEvent_Factless_AircraftID
ON [DW].[CrewAssignmentEvent_Factless] (AircraftID);
GO