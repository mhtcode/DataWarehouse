CREATE OR ALTER PROCEDURE [SA].[ETL_PointConversionRate]
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
        'ETL_PointConversionRate',
        'Source.PointConversionRate',
        'SA.PointConversionRate',
        'Procedure started - awaiting completion',
        @StartTime,
        'Fatal'
    );
    SET @LogID = SCOPE_IDENTITY();

    BEGIN TRY
        -- 2) Perform the merge
        MERGE [SA].[PointConversionRate] AS TARGET
        USING [Source].[PointConversionRate] AS SOURCE
          ON TARGET.PointConversionRateID = SOURCE.PointConversionRateID

        WHEN MATCHED AND EXISTS (
            SELECT
                SOURCE.ConversionRate,
                SOURCE.CurrencyCode
            EXCEPT
            SELECT
                TARGET.ConversionRate,
                TARGET.CurrencyCode
        ) THEN
            UPDATE SET
                TARGET.ConversionRate                  = SOURCE.ConversionRate,
                TARGET.CurrencyCode                    = SOURCE.CurrencyCode,
                TARGET.StagingLastUpdateTimestampUTC   = GETUTCDATE()

        WHEN NOT MATCHED BY TARGET THEN
            INSERT (
                PointConversionRateID,
                ConversionRate,
                CurrencyCode,
                StagingLoadTimestampUTC,
                SourceSystem
            )
            VALUES (
                SOURCE.PointConversionRateID,
                SOURCE.ConversionRate,
                SOURCE.CurrencyCode,
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
