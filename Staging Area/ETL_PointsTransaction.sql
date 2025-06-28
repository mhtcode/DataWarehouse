CREATE OR ALTER PROCEDURE [SA].[ETL_PointsTransaction]
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
        'ETL_PointsTransaction',
        'Source.PointsTransaction',
        'SA.PointsTransaction',
        'Procedure started - awaiting completion',
        @StartTime,
        'Fatal'
    );
    SET @LogID = SCOPE_IDENTITY();

    BEGIN TRY
        -- 2) Perform the merge
        MERGE [SA].[PointsTransaction] AS TARGET
        USING [Source].[PointsTransaction] AS SOURCE
          ON TARGET.PointsTransactionID = SOURCE.PointsTransactionID

        WHEN MATCHED AND EXISTS (
            SELECT
                SOURCE.AccountID,
                SOURCE.TransactionDate,
                SOURCE.LoyaltyTransactionTypeID,
                SOURCE.PointsChange,
                SOURCE.BalanceAfterTransaction,
                SOURCE.CurrencyValue,
                SOURCE.ConversionRate,
                SOURCE.PointConversionRateID,
                SOURCE.Description,
                SOURCE.ServiceOfferingID,
                SOURCE.FlightDetailID
            EXCEPT
            SELECT
                TARGET.AccountID,
                TARGET.TransactionDate,
                TARGET.LoyaltyTransactionTypeID,
                TARGET.PointsChange,
                TARGET.BalanceAfterTransaction,
                TARGET.CurrencyValue,
                TARGET.ConversionRate,
                TARGET.PointConversionRateID,
                TARGET.Description,
                TARGET.ServiceOfferingID,
                TARGET.FlightDetailID
        ) THEN
            UPDATE SET
                TARGET.AccountID                     = SOURCE.AccountID,
                TARGET.TransactionDate               = SOURCE.TransactionDate,
                TARGET.LoyaltyTransactionTypeID      = SOURCE.LoyaltyTransactionTypeID,
                TARGET.PointsChange                  = SOURCE.PointsChange,
                TARGET.BalanceAfterTransaction       = SOURCE.BalanceAfterTransaction,
                TARGET.CurrencyValue                      = SOURCE.CurrencyValue,
                TARGET.ConversionRate                = SOURCE.ConversionRate,
                TARGET.PointConversionRateID         = SOURCE.PointConversionRateID,
                TARGET.Description                   = NULLIF(LTRIM(RTRIM(SOURCE.Description)), ''),
                TARGET.ServiceOfferingID             = SOURCE.ServiceOfferingID,
                TARGET.FlightDetailID                = SOURCE.FlightDetailID,
                TARGET.StagingLastUpdateTimestampUTC = GETUTCDATE()

        WHEN NOT MATCHED BY TARGET THEN
            INSERT (
                PointsTransactionID,
                AccountID,
                TransactionDate,
                LoyaltyTransactionTypeID,
                PointsChange,
                BalanceAfterTransaction,
                CurrencyValue,
                ConversionRate,
                PointConversionRateID,
                Description,
                ServiceOfferingID,
                FlightDetailID,
                StagingLoadTimestampUTC,
                SourceSystem
            ) VALUES (
                SOURCE.PointsTransactionID,
                SOURCE.AccountID,
                SOURCE.TransactionDate,
                SOURCE.LoyaltyTransactionTypeID,
                SOURCE.PointsChange,
                SOURCE.BalanceAfterTransaction,
                SOURCE.CurrencyValue,
                SOURCE.ConversionRate,
                SOURCE.PointConversionRateID,
                NULLIF(LTRIM(RTRIM(SOURCE.Description)), ''),
                SOURCE.ServiceOfferingID,
                SOURCE.FlightDetailID,
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
