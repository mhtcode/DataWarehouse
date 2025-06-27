CREATE OR ALTER PROCEDURE [SA].[ETL_LoyaltyTransactionType]
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
        'ETL_LoyaltyTransactionType',
        'Source.LoyaltyTransactionType',
        'SA.LoyaltyTransactionType',
        'Procedure started - awaiting completion',
        @StartTime,
        'Fatal'
    );
    SET @LogID = SCOPE_IDENTITY();

    BEGIN TRY
        -- 2) Perform the merge
        MERGE [SA].[LoyaltyTransactionType] AS TARGET
        USING [Source].[LoyaltyTransactionType] AS SOURCE
          ON TARGET.LoyaltyTransactionTypeID = SOURCE.LoyaltyTransactionTypeID

        -- Update existing records if any relevant column has changed
        WHEN MATCHED AND EXISTS (
            SELECT SOURCE.TypeName
            EXCEPT
            SELECT TARGET.TypeName
        ) THEN
            UPDATE SET
                TARGET.TypeName                    = SOURCE.TypeName,
                TARGET.StagingLastUpdateTimestampUTC = GETUTCDATE()

        -- Insert new records
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
