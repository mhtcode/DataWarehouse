CREATE OR ALTER PROCEDURE [SA].[ETL_Item]
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
        'ETL_Item',
        'Source.Item',
        'SA.Item',
        'Procedure started - awaiting completion',
        @StartTime,
        'Fatal'
    );
    SET @LogID = SCOPE_IDENTITY();

    BEGIN TRY
        MERGE [SA].[Item] AS TARGET
        USING [Source].[Item] AS SOURCE
          ON TARGET.ItemID = SOURCE.ItemID

        WHEN MATCHED AND (
                ISNULL(TARGET.ItemName, '')           <> ISNULL(LTRIM(RTRIM(SOURCE.ItemName)), '')
             OR ISNULL(TARGET.Description, '')        <> ISNULL(LTRIM(RTRIM(SOURCE.Description)), '')
             OR ISNULL(TARGET.BasePrice, -1)          <> ISNULL(SOURCE.BasePrice, -1)
             OR ISNULL(TARGET.IsLoyaltyRedeemable,0)  <> ISNULL(SOURCE.IsLoyaltyRedeemable,0)
        ) THEN
            UPDATE SET
                TARGET.ItemName            = NULLIF(LTRIM(RTRIM(SOURCE.ItemName)), ''),
                TARGET.Description         = NULLIF(LTRIM(RTRIM(SOURCE.Description)), ''),
                TARGET.BasePrice           = SOURCE.BasePrice,
                TARGET.IsLoyaltyRedeemable = SOURCE.IsLoyaltyRedeemable,
                TARGET.StagingLastUpdateTimestampUTC = GETUTCDATE(),
                TARGET.SourceSystem        = 'OperationalDB'

        WHEN NOT MATCHED BY TARGET THEN
            INSERT (
                ItemID,
                ItemName,
                Description,
                BasePrice,
                IsLoyaltyRedeemable,
                StagingLoadTimestampUTC,
                SourceSystem
            )
            VALUES (
                SOURCE.ItemID,
                NULLIF(LTRIM(RTRIM(SOURCE.ItemName)), ''),
                NULLIF(LTRIM(RTRIM(SOURCE.Description)), ''),
                SOURCE.BasePrice,
                SOURCE.IsLoyaltyRedeemable,
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
