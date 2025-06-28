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