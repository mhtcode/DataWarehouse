CREATE TABLE [DW].[PartReplacement_TransactionalFact] (
    -- Dimensional Keys
    [AircraftID]                INT NOT NULL,   -- FK to DW.DimAircraft.AircraftID, from SA.PartReplacement.AircraftID
    [PartID]                    INT NOT NULL,   -- FK to DW.DimPart.PartID, from SA.PartReplacement.PartID
    [MaintenanceLocationKey]    INT NOT NULL,   -- FK to DW.DimMaintenanceLocation.MaintenanceLocationKey (SCD2), lookup by Location+Date from SA.PartReplacement.MaintenanceLocationID & ReplacementDate
    [ReplacementDateKey]        INT NOT NULL,   -- FK to DW.DimDateTime.DateKey, from SA.PartReplacement.ReplacementDate

    -- Business Measures
    [Quantity]                  INT NULL,           -- Direct from SA.PartReplacement.Quantity
    [PartCost]                  DECIMAL(18,2) NULL, -- Direct from SA.PartReplacement.PartCost
    [TotalPartCost]             DECIMAL(18,2) NULL  -- Direct from SA.PartReplacement.TotalPartCost, or Quantity * PartCost if not provided
);
GO
