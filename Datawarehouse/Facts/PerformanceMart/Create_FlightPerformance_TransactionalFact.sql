CREATE TABLE [DW].[FlightPerformance_TransactionalFact] (
    [ScheduledDepartureId] DATETIME NULL,  -- from SA.FlightDetail.ScheduledDepartureDateTime
    [ScheduledArrivalId]   DATETIME NULL,  -- from SA.FlightDetail.ScheduledArrivalDateTime

    [ActualDepartureId]    DATETIME NULL,  -- from SA.FlightOperation.ActualDepartureDateTime
    [ActualArrivalId]      DATETIME NULL,  -- from SA.FlightOperation.ActualArrivalDateTime

    [DepartureAirportId]   INT NULL,       -- from SA.FlightDetail.DepartureAirportID
    [ArrivalAirportId]     INT NULL,       -- from SA.FlightDetail.ArrivalAirportID

    [AircraftId]           INT NULL,       -- from SA.FlightDetail.AircraftID
    [AirlineId]            INT NULL,       -- from SA.FlightDetail.AirlineID

    [DepartureDelayMinutes] INT NULL,      -- from SA.FlightOperation.DelayMinutes
    [ArrivalDelayMinutes]  INT NULL,       -- from SA.FlightOperation.DelayMinutes

    [FlightDurationActual]   INT NULL,     -- Actual flight duration in minutes (DATEDIFF in ETL)
    [FlightDurationScheduled] INT NULL,    -- Scheduled flight duration in minutes (DATEDIFF in ETL)

    [LoadFactor]            FLOAT NULL,    -- from SA.FlightOperation.LoadFactor
    [DelaySeverityScore]    FLOAT NULL     -- from SA.FlightOperation.DelaySeverityScore
);
GO

CREATE NONCLUSTERED INDEX IX_FlightPerformance_TransactionalFact_ScheduledDepartureId
ON [DW].[FlightPerformance_TransactionalFact] (ScheduledDepartureId);
GO

CREATE NONCLUSTERED INDEX IX_FlightPerformance_TransactionalFact_ScheduledArrivalId
ON [DW].[FlightPerformance_TransactionalFact] (ScheduledArrivalId);
GO

CREATE NONCLUSTERED INDEX IX_FlightPerformance_TransactionalFact_ActualDepartureId
ON [DW].[FlightPerformance_TransactionalFact] (ActualDepartureId);
GO

CREATE NONCLUSTERED INDEX IX_FlightPerformance_TransactionalFact_ActualArrivalId
ON [DW].[FlightPerformance_TransactionalFact] (ActualArrivalId);
GO

CREATE NONCLUSTERED INDEX IX_FlightPerformance_TransactionalFact_AirlineId
ON [DW].[FlightPerformance_TransactionalFact] (AirlineId);
GO

CREATE NONCLUSTERED INDEX IX_FlightPerformance_TransactionalFact_AircraftId
ON [DW].[FlightPerformance_TransactionalFact] (AircraftId);
GO

CREATE NONCLUSTERED INDEX IX_FlightPerformance_TransactionalFact_Route
ON [DW].[FlightPerformance_TransactionalFact] (DepartureAirportId, ArrivalAirportId);
GO

CREATE NONCLUSTERED INDEX IX_FlightPerformance_TransactionalFact_DepartureAirportId
ON [DW].[FlightPerformance_TransactionalFact] (DepartureAirportId);
GO
