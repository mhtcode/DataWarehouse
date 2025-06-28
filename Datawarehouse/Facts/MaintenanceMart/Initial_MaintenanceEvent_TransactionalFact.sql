CREATE OR ALTER PROCEDURE [DW].[Initial_MaintenanceEvent_TransactionalFact]
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @StartTime DATETIME2(3) = SYSUTCDATETIME(), @RowCount INT, @LogID BIGINT;

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
        INSERT INTO [DW].[MaintenanceEvent_TransactionalFact] (
            AircraftID,
            MaintenanceTypeID,
            MaintenanceLocationKey,
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
            -- AircraftID: direct FK
            SA.AircraftID,
            -- MaintenanceTypeID: direct FK
            SA.MaintenanceTypeID,
            -- MaintenanceLocationKey: SCD2 logic
            DL.LocationKey,
            -- TechnicianID: direct FK
            SA.TechnicianID,
            -- MaintenanceDateKey: date dimension FK
            DT.DateKey,
            -- Measures
            SA.DowntimeHours,
            SA.LaborHours,
            SA.LaborCost,
            SA.TotalPartsCost,
            SA.TotalMaintenanceCost,
            SA.DistinctIssuesSolved
        FROM [SA].[MaintenanceEvent] SA
        -- MaintenanceLocationKey SCD2 lookup
        INNER JOIN [DW].[DimMaintenanceLocation] DL
            ON DL.LocationID = SA.LocationID
            AND SA.MaintenanceDate >= DL.EffectiveFrom
            AND (SA.MaintenanceDate < DL.EffectiveTo OR DL.EffectiveTo IS NULL)
            AND DL.CityIsCurrent = 1
        -- Date dimension lookup (convert date to key)
        INNER JOIN [DW].[DimDateTime] DT
            ON DT.[Date] = SA.MaintenanceDate
        -- MaintenanceType join is not needed unless you want to validate FK exists.
        ;

        SET @RowCount = @@ROWCOUNT;

        UPDATE [DW].[ETL_Log]
        SET ChangeDescription = CONCAT('Loaded ', @RowCount, ' rows into MaintenanceEvent_TransactionalFact'),
            RowsAffected = @RowCount,
            DurationSec = DATEDIFF(SECOND, @StartTime, SYSUTCDATETIME()),
            Status = 'Success'
        WHERE LogID = @LogID;

    END TRY
    BEGIN CATCH
        UPDATE [DW].[ETL_Log]
        SET ChangeDescription = 'Load failed: ' + ERROR_MESSAGE(),
            DurationSec = DATEDIFF(SECOND, @StartTime, SYSUTCDATETIME()),
            Status = 'Error',
            Message = ERROR_MESSAGE()
        WHERE LogID = @LogID;
        THROW;
    END CATCH
END
GO
