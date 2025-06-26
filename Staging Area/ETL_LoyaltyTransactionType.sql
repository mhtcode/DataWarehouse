CREATE OR ALTER PROCEDURE [SA].[ETL_LoyaltyTransactionType]
AS
BEGIN
    MERGE [SA].[LoyaltyTransactionType] AS TARGET
    USING [Source].[LoyaltyTransactionType] AS SOURCE
        ON (TARGET.LoyaltyTransactionTypeID = SOURCE.LoyaltyTransactionTypeID)

    -- Update existing records if any relevant column has changed
    WHEN MATCHED AND EXISTS (
        SELECT SOURCE.TypeName
        EXCEPT
        SELECT TARGET.TypeName
    ) THEN
        UPDATE SET
            TARGET.TypeName = SOURCE.TypeName,
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
END
GO
