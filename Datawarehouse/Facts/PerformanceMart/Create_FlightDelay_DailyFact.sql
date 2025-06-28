CREATE TABLE [DW].[FlightDelay_DailyFact] (
    [SnapshotDateKey]         DATE    NOT NULL,  
    [AirlineID]              INT    NOT NULL,  
    [DepartureAirportID]     INT    NOT NULL,  
    [ArrivalAirportID]       INT    NOT NULL,  

    [DailyFlightsNumber]            INT    NULL,
    [DailyDelayedFlightsNumber]          INT    NULL,
    [DailyCancelledFlightsNumber]        INT    NULL,

    [DailyAvgDepartureDelayMinutes] FLOAT  NULL,
    [DailyAvgArrivalDelayMinutes]   FLOAT  NULL,
    [DailyMaxDelayMinutes]         INT    NULL,

    [DailyDelayRate]               FLOAT  NULL,
    [DailyOnTimePercentage]        FLOAT  NULL
);
GO