CREATE TABLE [DW].[AircraftHealth_MonthlyFact] (
    -- Dimensional Keys
    [SnapshotDateKey]               INT NOT NULL,   -- FK to DW.DimDateTime.DateKey, from ETL snapshot date
    [AircraftID]                    INT NOT NULL,   -- FK to DW.DimAircraft.AircraftID, from SA or derived
    [CarrierID]                     INT NOT NULL,   -- FK to DW.DimAirline.AirlineID, from SA.Aircraft or lookup

    -- Business Measures
    [TotalHours]                    FLOAT NULL,         -- Cumulative flight hours up to snapshot date (needs calculation from flight logs/history, or direct if tracked)
    [TotalCycles]                   INT NULL,           -- Cumulative takeoff/landing cycles up to snapshot date (as above, calculated or direct if tracked)
    [DaysSinceLastMaintenance]      INT NULL,           -- Days between snapshot date and max(MaintenanceEvent.MaintenanceDate) for that AircraftID
    [MaintenanceCostLastPeriod]     DECIMAL(18,2) NULL  -- Sum of MaintenanceEvent.TotalMaintenanceCost for AircraftID during this period (last interval)
);
GO
