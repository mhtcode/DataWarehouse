CREATE TABLE [DW].[MaintenanceEvent_TransactionalFact] (
    -- Dimensional Keys
    [AircraftID]                INT NOT NULL,   -- FK to DW.DimAircraft.AircraftID, from SA.MaintenanceEvent.AircraftID
    [MaintenanceTypeID]         integer NOT NULL,   -- FK to DW.DimMaintenanceType.MaintenanceTypeID, from SA.MaintenanceEvent.MaintenanceTypeID
    [LocationKey]    INT NOT NULL,   -- FK to DW.DimMaintenanceLocation.LocationKey (SCD2), lookup by Location+Date from SA.MaintenanceEvent.LocationID & MaintenanceDate
    [TechnicianID]              integer NOT NULL,   -- FK to DW.DimTechnician.TechnicianID, from SA.MaintenanceEvent.TechnicianID
    [MaintenanceDateKey]        datetime NOT NULL,   -- FK to DW.DimDateTime.DateKey, from SA.MaintenanceEvent.MaintenanceDate

    -- Business Measures
    [DowntimeHours]             FLOAT NULL,         -- Direct from SA.MaintenanceEvent.DowntimeHours
    [LaborHours]                FLOAT NULL,         -- Direct from SA.MaintenanceEvent.LaborHours
    [LaborCost]                 DECIMAL(18,2) NULL, -- Direct from SA.MaintenanceEvent.LaborCost
    [TotalPartsCost]            DECIMAL(18,2) NULL, -- Direct from SA.MaintenanceEvent.TotalPartsCost
    [TotalMaintenanceCost]      DECIMAL(18,2) NULL, -- Direct from SA.MaintenanceEvent.TotalMaintenanceCost
    [DistinctIssuesSolved]      INT NULL            -- Direct from SA.MaintenanceEvent.DistinctIssuesSolved, or COUNT of related resolved issues if normalized
);
GO
