CREATE OR ALTER PROCEDURE [SA].[ETL_MaintenanceEvent]
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE
        @StartTime    DATETIME2(3) = SYSUTCDATETIME(),
        @RowsAffected INT,
        @LogID        BIGINT;

    -- 1) Insert initial log entry
    INSERT INTO [SA].[ETL_Log] (
        ProcedureName,
        SourceTable,
        TargetTable,
        ChangeDescription,
        ActionTime,
        Status
    ) VALUES (
        'ETL_MaintenanceEvent',
        'Source.MaintenanceEvent',
        'SA.MaintenanceEvent',
        'Procedure started - awaiting completion',
        @StartTime,
        'Fatal'
    );
    SET @LogID = SCOPE_IDENTITY();

    BEGIN TRY
        -- 2) Perform the MERGE
        MERGE [SA].[MaintenanceEvent] AS TARGET
        USING [Source].[MaintenanceEvent] AS SOURCE
          ON TARGET.MaintenanceEventID = SOURCE.MaintenanceEventID

        WHEN MATCHED AND EXISTS (
            SELECT
                SOURCE.AircraftID, SOURCE.MaintenanceTypeID, SOURCE.LocationID, SOURCE.TechnicianID,
                SOURCE.MaintenanceDate, SOURCE.DowntimeHours, SOURCE.LaborHours, SOURCE.LaborCost, SOURCE.TotalPartsCost,
                SOURCE.TotalMaintenanceCost, SOURCE.DistinctIssuesSolved, SOURCE.Description
            EXCEPT
            SELECT
                TARGET.AircraftID, TARGET.MaintenanceTypeID, TARGET.LocationID, TARGET.TechnicianID,
                TARGET.MaintenanceDate, TARGET.DowntimeHours, TARGET.LaborHours, TARGET.LaborCost, TARGET.TotalPartsCost,
                TARGET.TotalMaintenanceCost, TARGET.DistinctIssuesSolved, TARGET.Description
        ) THEN
            UPDATE SET
                TARGET.AircraftID = SOURCE.AircraftID,
                TARGET.MaintenanceTypeID = SOURCE.MaintenanceTypeID,
                TARGET.LocationID = SOURCE.LocationID,
                TARGET.TechnicianID = SOURCE.TechnicianID,
                TARGET.MaintenanceDate = SOURCE.MaintenanceDate,
                TARGET.DowntimeHours = SOURCE.DowntimeHours,
                TARGET.LaborHours = SOURCE.LaborHours,
                TARGET.LaborCost = SOURCE.LaborCost,
                TARGET.TotalPartsCost = SOURCE.TotalPartsCost,
                TARGET.TotalMaintenanceCost = SOURCE.TotalMaintenanceCost,
                TARGET.DistinctIssuesSolved = SOURCE.DistinctIssuesSolved,
                TARGET.Description = SOURCE.Description,
                TARGET.StagingLastUpdateTimestampUTC = GETUTCDATE()

        WHEN NOT MATCHED BY TARGET THEN
            INSERT (
                MaintenanceEventID, AircraftID, MaintenanceTypeID, LocationID,
                TechnicianID, MaintenanceDate, DowntimeHours, LaborHours, LaborCost,
                TotalPartsCost, TotalMaintenanceCost, DistinctIssuesSolved, Description,
                StagingLoadTimestampUTC, SourceSystem
            ) VALUES (
                SOURCE.MaintenanceEventID, SOURCE.AircraftID, SOURCE.MaintenanceTypeID, SOURCE.LocationID,
                SOURCE.TechnicianID, SOURCE.MaintenanceDate, SOURCE.DowntimeHours, SOURCE.LaborHours, SOURCE.LaborCost,
                SOURCE.TotalPartsCost, SOURCE.TotalMaintenanceCost, SOURCE.DistinctIssuesSolved, SOURCE.Description,
                GETUTCDATE(), 'OperationalDB'
            );

        SET @RowsAffected = @@ROWCOUNT;

        -- 3) Update log to Success
        UPDATE [SA].[ETL_Log]
        SET
            ChangeDescription = CONCAT('Merge complete: rows affected=', @RowsAffected),
            RowsAffected      = @RowsAffected,
            DurationSec       = DATEDIFF(SECOND, @StartTime, SYSUTCDATETIME()),
            Status            = 'Success'
        WHERE LogID = @LogID;
    END TRY
    BEGIN CATCH
        UPDATE [SA].[ETL_Log]
        SET
            ChangeDescription = 'Merge failed',
            DurationSec       = DATEDIFF(SECOND, @StartTime, SYSUTCDATETIME()),
            Status            = 'Error',
            Message           = ERROR_MESSAGE()
        WHERE LogID = @LogID;
        THROW;
    END CATCH
END;
GO
