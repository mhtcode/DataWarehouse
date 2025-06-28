CREATE TABLE [DW].[FlightDelay_ACCFact] (  
    [AirlineID]              INT    NOT NULL,  
    [DepartureAirportID]     INT    NOT NULL,  
    [ArrivalAirportID]       INT    NOT NULL,  

    [TotalFlightsNumber]            INT    NULL,
    [TotalDelayedFlightsNumber]          INT    NULL,
    [TotalCancelledFlightsNumber]        INT    NULL,

    [TotalAvgDepartureDelayMinutes] FLOAT  NULL,
    [TotalAvgArrivalDelayMinutes]   FLOAT  NULL,
    [TotalMaxDelayMinutes]         INT    NULL,

    [TotalDelayRate]               FLOAT  NULL,
    [TotalOnTimePercentage]        FLOAT  NULL
);
GO