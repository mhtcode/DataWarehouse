CREATE OR ALTER PROCEDURE [SA].[ETL_ServiceOfferingItem]
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE
        @StartTime     DATETIME2(3) = SYSUTCDATETIME(),
        @RowsAffected  INT,
        @LogID         BIGINT;

    -- 1) Assume fatal: insert initial log entry
    INSERT INTO [SA].[ETL_Log] (
        ProcedureName,
        SourceTable,
        TargetTable,
        ChangeDescription,
        ActionTime,
        Status
    ) VALUES (
        'ETL_ServiceOfferingItem',
        'Source.ServiceOfferingItem',
        'SA.ServiceOfferingItem',
        'Procedure started - awaiting completion',
        @StartTime,
        'Fatal'
    );
    SET @LogID = SCOPE_IDENTITY();

    BEGIN TRY
        -- 2) Perform the merge
        MERGE [SA].[ServiceOfferingItem] AS TARGET
        USING [Source].[ServiceOfferingItem] AS SOURCE
          ON TARGET.ServiceOfferingID = SOURCE.ServiceOfferingID
         AND TARGET.ItemID               = SOURCE.ItemID

        WHEN MATCHED AND (
                ISNULL(TARGET.Quantity, -1) <> ISNULL(SOURCE.Quantity, -1)
        ) THEN
            UPDATE SET
                TARGET.Quantity                     = SOURCE.Quantity,
                TARGET.StagingLastUpdateTimestampUTC = GETUTCDATE(),
                TARGET.SourceSystem                = 'OperationalDB'

        WHEN NOT MATCHED BY TARGET THEN
            INSERT (
                ServiceOfferingID,
                ItemID,
                Quantity,
                StagingLoadTimestampUTC,
                SourceSystem
            ) VALUES (
                SOURCE.ServiceOfferingID,
                SOURCE.ItemID,
                SOURCE.Quantity,
                GETUTCDATE(),
                'OperationalDB'
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
        -- 4) Update log to Error
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
