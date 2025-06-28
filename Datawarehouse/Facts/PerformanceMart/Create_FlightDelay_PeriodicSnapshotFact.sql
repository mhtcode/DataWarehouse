CREATE TABLE [DW].[FlightDelay_PeriodicSnapshotFact] (
    [SnapshotDateKey]         DATE    NOT NULL,  
    [AirlineKey]              INT    NOT NULL,  
    [DepartureAirportKey]     INT    NOT NULL,  
    [ArrivalAirportKey]       INT    NOT NULL,  

    [TotalFlights]            INT    NULL,
    [DelayedFlights]          INT    NULL,
    [CancelledFlights]        INT    NULL,

    [AvgDepartureDelayMinutes] FLOAT  NULL,
    [AvgArrivalDelayMinutes]   FLOAT  NULL,
    [MaxDelayMinutes]         INT    NULL,

    [DelayRate]               FLOAT  NULL,
    [OnTimePercentage]        FLOAT  NULL
);
GO