CREATE OR ALTER PROCEDURE [SA].[ETL_AccountTierHistory]
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
    ) VALUES (
        'ETL_AccountTierHistory',
        'Source.AccountTierHistory',
        'SA.AccountTierHistory',
        'Procedure started - awaiting completion',
        @StartTime,
        'Fatal'
    );
    SET @LogID = SCOPE_IDENTITY();

    BEGIN TRY
        MERGE [SA].[AccountTierHistory] AS TARGET
        USING [Source].[AccountTierHistory] AS SOURCE
          ON (TARGET.HistoryID = SOURCE.HistoryID)

        WHEN MATCHED AND EXISTS (
            SELECT
                SOURCE.HistoryID,
                SOURCE.AccountID,
                SOURCE.LoyaltyTierID,
                SOURCE.EffectiveFrom,
                SOURCE.EffectiveTo,
                SOURCE.CurrentFlag
            EXCEPT
            SELECT
                TARGET.HistoryID,
                TARGET.AccountID,
                TARGET.LoyaltyTierID,
                TARGET.EffectiveFrom,
                TARGET.EffectiveTo,
                TARGET.CurrentFlag
        ) THEN
            UPDATE SET
                TARGET.AccountID                       = SOURCE.AccountID,
                TARGET.LoyaltyTierID                   = SOURCE.LoyaltyTierID,
                TARGET.EffectiveFrom                   = SOURCE.EffectiveFrom,
                TARGET.EffectiveTo                     = SOURCE.EffectiveTo,
                TARGET.CurrentFlag                     = SOURCE.CurrentFlag,
                TARGET.StagingLastUpdateTimestampUTC   = GETUTCDATE()

        WHEN NOT MATCHED BY TARGET THEN
            INSERT (
                HistoryID,
                AccountID,
                LoyaltyTierID,
                EffectiveFrom,
                EffectiveTo,
                CurrentFlag,
                StagingLoadTimestampUTC,
                SourceSystem
            )
            VALUES (
                SOURCE.HistoryID,
                SOURCE.AccountID,
                SOURCE.LoyaltyTierID,
                SOURCE.EffectiveFrom,
                SOURCE.EffectiveTo,
                SOURCE.CurrentFlag,
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
