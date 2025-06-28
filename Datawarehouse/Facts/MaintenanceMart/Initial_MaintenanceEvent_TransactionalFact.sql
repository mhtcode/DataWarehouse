CREATE OR ALTER PROCEDURE [DW].[Initial_MaintenanceEvent_TransactionalFact]
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE 
        @StartTime  DATETIME2(3) = SYSUTCDATETIME(),
        @RowCount   INT,
        @LogID      BIGINT;

    -- 1. Log procedure start
    INSERT INTO [DW].[ETL_Log] (
        ProcedureName, TargetTable, ChangeDescription, ActionTime, Status
    ) VALUES (
        'Initial_MaintenanceEvent_TransactionalFact',
        'MaintenanceEvent_TransactionalFact',
        'Starting full initial load',
        @StartTime,
        'Running'
    );
    SET @LogID = SCOPE_IDENTITY();

    BEGIN TRY
        -- 2. Truncate the fact table for a clean load
        TRUNCATE TABLE [DW].[MaintenanceEvent_TransactionalFact];

        -- 3. Insert from SA.MaintenanceEvent + SCD2 Dim lookups
        INSERT INTO [DW].[MaintenanceEvent_TransactionalFact] (
            AircraftID,
            MaintenanceTypeID,
            LocationKey,   -- <-- This now matches [LocationKey]
            TechnicianID,
            MaintenanceDateKey,
            DowntimeHours,
            LaborHours,
            LaborCost,
            TotalPartsCost,
            TotalMaintenanceCost,
            DistinctIssuesSolved
        )
        SELECT
            SA.AircraftID,
            SA.MaintenanceTypeID,
            DL.LocationKey,    -- <-- Fixed column name!
            SA.TechnicianID,
            DT.DateTimeKey,
            SA.DowntimeHours,
            SA.LaborHours,
            SA.LaborCost,
            SA.TotalPartsCost,
            SA.TotalMaintenanceCost,
            SA.DistinctIssuesSolved
        FROM [SA].[MaintenanceEvent] SA
        -- SCD2 lookup for LocationKey (current at MaintenanceDate)
        INNER JOIN [DW].[DimMaintenanceLocation] DL
            ON DL.LocationID = SA.LocationID
            AND SA.MaintenanceDate >= DL.EffectiveFrom
            AND (SA.MaintenanceDate < DL.EffectiveTo OR DL.EffectiveTo IS NULL)
        -- Date dimension lookup for MaintenanceDateKey
        INNER JOIN [DW].[DimDateTime] DT
            ON CAST(DT.DateTimeKey AS DATE) = SA.MaintenanceDate;

        SET @RowCount = @@ROWCOUNT;

        -- 4. Log success
        UPDATE [DW].[ETL_Log]
        SET ChangeDescription = CONCAT('Loaded ', @RowCount, ' rows into MaintenanceEvent_TransactionalFact'),
            RowsAffected      = @RowCount,
            DurationSec       = DATEDIFF(SECOND, @StartTime, SYSUTCDATETIME()),
            Status            = 'Success'
        WHERE LogID = @LogID;

    END TRY
    BEGIN CATCH
        DECLARE @ErrMsg NVARCHAR(MAX) = ERROR_MESSAGE();
        UPDATE [DW].[ETL_Log]
        SET ChangeDescription = 'Load failed: ' + @ErrMsg,
            DurationSec       = DATEDIFF(SECOND, @StartTime, SYSUTCDATETIME()),
            Status            = 'Error',
            Message           = @ErrMsg
        WHERE LogID = @LogID;
        THROW;
    END CATCH
END
GO
