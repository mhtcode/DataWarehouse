CREATE OR ALTER PROCEDURE [SA].[ETL_LoyaltyTier]
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
        'ETL_LoyaltyTier',
        'Source.LoyaltyTier',
        'SA.LoyaltyTier',
        'Procedure started - awaiting completion',
        @StartTime,
        'Fatal'
    );
    SET @LogID = SCOPE_IDENTITY();

    BEGIN TRY
        -- 2) Perform the merge
        MERGE [SA].[LoyaltyTier] AS TARGET
        USING [Source].[LoyaltyTier] AS SOURCE
          ON (TARGET.LoyaltyTierID = SOURCE.LoyaltyTierID)

        -- Action for existing records that have changed
        WHEN MATCHED AND EXISTS (
            SELECT SOURCE.Name, SOURCE.MinPoints, SOURCE.Benefits
            EXCEPT
            SELECT TARGET.Name, TARGET.MinPoints, TARGET.Benefits
        ) THEN
            UPDATE SET
                TARGET.Name                          = NULLIF(TRIM(SOURCE.Name), ''),
                TARGET.MinPoints                     = SOURCE.MinPoints,
                TARGET.Benefits                      = NULLIF(TRIM(SOURCE.Benefits), ''),
                TARGET.StagingLastUpdateTimestampUTC = GETUTCDATE()

        -- Action for new records
        WHEN NOT MATCHED BY TARGET THEN
            INSERT (
                LoyaltyTierID,
                Name,
                MinPoints,
                Benefits,
                StagingLoadTimestampUTC,
                SourceSystem
            ) VALUES (
                SOURCE.LoyaltyTierID,
                NULLIF(TRIM(SOURCE.Name), ''),
                SOURCE.MinPoints,
                NULLIF(TRIM(SOURCE.Benefits), ''),
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
