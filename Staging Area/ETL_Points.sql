CREATE OR ALTER PROCEDURE [SA].[ETL_Points]
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE
        @StartTime     DATETIME2(3) = SYSUTCDATETIME(),
        @RowsAffected  INT,
        @LogID         BIGINT;

    INSERT INTO [SA].[ETL_Log] (
        ProcedureName,
        SourceTable,
        TargetTable,
        ChangeDescription,
        ActionTime,
        Status
    )
    VALUES (
        'ETL_Points',
        'Source.Points',
        'SA.Points',
        'Procedure started - awaiting completion',
        @StartTime,
        'Fatal'
    );
    SET @LogID = SCOPE_IDENTITY();

    BEGIN TRY
        MERGE [SA].[Points] AS TARGET
        USING [Source].[Points] AS SOURCE
          ON TARGET.PointsID = SOURCE.PointsID

        WHEN MATCHED AND EXISTS (
            SELECT
                SOURCE.AccountID,
                SOURCE.PointsBalance,
                SOURCE.EffectiveDate
            EXCEPT
            SELECT
                TARGET.AccountID,
                TARGET.PointsBalance,
                TARGET.EffectiveDate
        ) THEN
            UPDATE SET
                TARGET.AccountID                     = SOURCE.AccountID,
                TARGET.PointsBalance                 = SOURCE.PointsBalance,
                TARGET.EffectiveDate                 = SOURCE.EffectiveDate,
                TARGET.StagingLastUpdateTimestampUTC = GETUTCDATE()

        WHEN NOT MATCHED BY TARGET THEN
            INSERT (
                PointsID,
                AccountID,
                PointsBalance,
                EffectiveDate,
                StagingLoadTimestampUTC,
                SourceSystem
            )
            VALUES (
                SOURCE.PointsID,
                SOURCE.AccountID,
                SOURCE.PointsBalance,
                SOURCE.EffectiveDate,
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
