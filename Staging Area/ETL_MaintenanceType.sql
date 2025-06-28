CREATE OR ALTER PROCEDURE [SA].[ETL_MaintenanceType]
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE
        @StartTime    DATETIME2(3) = SYSUTCDATETIME(),
        @RowsAffected INT,
        @LogID        BIGINT;

    INSERT INTO [SA].[ETL_Log] (
        ProcedureName,
        SourceTable,
        TargetTable,
        ChangeDescription,
        ActionTime,
        Status
    ) VALUES (
        'ETL_MaintenanceType',
        'Source.MaintenanceType',
        'SA.MaintenanceType',
        'Procedure started - awaiting completion',
        @StartTime,
        'Fatal'
    );
    SET @LogID = SCOPE_IDENTITY();

    BEGIN TRY
        MERGE [SA].[MaintenanceType] AS TARGET
        USING [Source].[MaintenanceType] AS SOURCE
          ON TARGET.MaintenanceTypeID = SOURCE.MaintenanceTypeID

        WHEN MATCHED AND EXISTS (
            SELECT
                SOURCE.Name, SOURCE.Category, SOURCE.Description
            EXCEPT
            SELECT
                TARGET.Name, TARGET.Category, TARGET.Description
        ) THEN
            UPDATE SET
                TARGET.Name                         = SOURCE.Name,
                TARGET.Category                     = SOURCE.Category,
                TARGET.Description                  = SOURCE.Description,
                TARGET.StagingLastUpdateTimestampUTC = GETUTCDATE()

        WHEN NOT MATCHED BY TARGET THEN
            INSERT (
                MaintenanceTypeID,
                Name,
                Category,
                Description,
                StagingLoadTimestampUTC,
                SourceSystem
            ) VALUES (
                SOURCE.MaintenanceTypeID,
                SOURCE.Name,
                SOURCE.Category,
                SOURCE.Description,
                GETUTCDATE(),
                'OperationalDB'
            );

        SET @RowsAffected = @@ROWCOUNT;

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
