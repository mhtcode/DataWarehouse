CREATE OR ALTER PROCEDURE [SA].[ETL_LoyaltyTransactionType]
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
        'ETL_LoyaltyTransactionType',
        'Source.LoyaltyTransactionType',
        'SA.LoyaltyTransactionType',
        'Procedure started - awaiting completion',
        @StartTime,
        'Fatal'
    );
    SET @LogID = SCOPE_IDENTITY();

    BEGIN TRY
        MERGE [SA].[LoyaltyTransactionType] AS TARGET
        USING [Source].[LoyaltyTransactionType] AS SOURCE
          ON TARGET.LoyaltyTransactionTypeID = SOURCE.LoyaltyTransactionTypeID

        WHEN MATCHED AND EXISTS (
            SELECT SOURCE.TypeName
            EXCEPT
            SELECT TARGET.TypeName
        ) THEN
            UPDATE SET
                TARGET.TypeName                    = SOURCE.TypeName,
                TARGET.StagingLastUpdateTimestampUTC = GETUTCDATE()

        WHEN NOT MATCHED BY TARGET THEN
            INSERT (
                LoyaltyTransactionTypeID,
                TypeName,
                StagingLoadTimestampUTC,
                SourceSystem
            )
            VALUES (
                SOURCE.LoyaltyTransactionTypeID,
                SOURCE.TypeName,
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
