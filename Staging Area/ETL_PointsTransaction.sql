CREATE OR ALTER PROCEDURE [SA].[ETL_PointsTransaction]
AS
BEGIN
    SET NOCOUNT ON;

    MERGE [SA].[PointsTransaction] AS TARGET
    USING [Source].[PointsTransaction] AS SOURCE
        ON (TARGET.PointsTransactionID = SOURCE.PointsTransactionID)

    -- Update all changed columns (SCD1 logic)
    WHEN MATCHED AND EXISTS (
        SELECT
            SOURCE.AccountID,
            SOURCE.TransactionDate,
            SOURCE.LoyaltyTransactionTypeID,
            SOURCE.PointsChange,
            SOURCE.BalanceAfterTransaction,
            SOURCE.USDValue,
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
            TARGET.USDValue,
            TARGET.ConversionRate,
            TARGET.PointConversionRateID,
            TARGET.Description,
            TARGET.ServiceOfferingID,
            TARGET.FlightDetailID
    ) THEN
        UPDATE SET
            TARGET.AccountID = SOURCE.AccountID,
            TARGET.TransactionDate = SOURCE.TransactionDate,
            TARGET.LoyaltyTransactionTypeID = SOURCE.LoyaltyTransactionTypeID,
            TARGET.PointsChange = SOURCE.PointsChange,
            TARGET.BalanceAfterTransaction = SOURCE.BalanceAfterTransaction,
            TARGET.USDValue = SOURCE.USDValue,
            TARGET.ConversionRate = SOURCE.ConversionRate,
            TARGET.PointConversionRateID = SOURCE.PointConversionRateID,
            TARGET.Description = NULLIF(LTRIM(RTRIM(SOURCE.Description)), ''),
            TARGET.ServiceOfferingID = SOURCE.ServiceOfferingID,
            TARGET.FlightDetailID = SOURCE.FlightDetailID,
            TARGET.StagingLastUpdateTimestampUTC = GETUTCDATE()

    -- Insert new records
    WHEN NOT MATCHED BY TARGET THEN
        INSERT (
            PointsTransactionID,
            AccountID,
            TransactionDate,
            LoyaltyTransactionTypeID,
            PointsChange,
            BalanceAfterTransaction,
            USDValue,
            ConversionRate,
            PointConversionRateID,
            Description,
            ServiceOfferingID,
            FlightDetailID,
            StagingLoadTimestampUTC,
            SourceSystem
        )
        VALUES (
            SOURCE.PointsTransactionID,
            SOURCE.AccountID,
            SOURCE.TransactionDate,
            SOURCE.LoyaltyTransactionTypeID,
            SOURCE.PointsChange,
            SOURCE.BalanceAfterTransaction,
            SOURCE.USDValue,
            SOURCE.ConversionRate,
            SOURCE.PointConversionRateID,
            NULLIF(LTRIM(RTRIM(SOURCE.Description)), ''),
            SOURCE.ServiceOfferingID,
            SOURCE.FlightDetailID,
            GETUTCDATE(),
            'OperationalDB'
        );

END
GO
