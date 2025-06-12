CREATE OR ALTER PROCEDURE [SA].[ETL_PointsTransaction]
AS
BEGIN
    MERGE [SA].[PointsTransaction] AS TARGET
    USING [Source].[PointsTransaction] AS SOURCE
    ON (TARGET.TransactionID = SOURCE.TransactionID)

    -- Action for existing records that have changed
    WHEN MATCHED AND EXISTS (
        -- This clause correctly compares all relevant columns for any changes.
        SELECT SOURCE.AccountID, SOURCE.TransactionDate, SOURCE.TransactionType, SOURCE.PointsChange, SOURCE.Description, SOURCE.ServiceOfferingID
        EXCEPT
        SELECT TARGET.AccountID, TARGET.TransactionDate, TARGET.TransactionType, TARGET.PointsChange, TARGET.Description, TARGET.ServiceOfferingID
    ) THEN
        UPDATE SET
            TARGET.AccountID = SOURCE.AccountID,
            TARGET.TransactionDate = SOURCE.TransactionDate,
            TARGET.TransactionType = NULLIF(TRIM(SOURCE.TransactionType), ''),
            TARGET.PointsChange = SOURCE.PointsChange,
            TARGET.Description = NULLIF(TRIM(SOURCE.Description), ''),
            TARGET.ServiceOfferingID = SOURCE.ServiceOfferingID,
            TARGET.StagingLastUpdateTimestampUTC = GETUTCDATE()

    -- Action for new records
    WHEN NOT MATCHED BY TARGET THEN
        INSERT (
            TransactionID,
            AccountID,
            TransactionDate,
            TransactionType,
            PointsChange,
            Description,
            ServiceOfferingID,
            StagingLoadTimestampUTC,
            SourceSystem
        )
        VALUES (
            SOURCE.TransactionID,
            SOURCE.AccountID,
            SOURCE.TransactionDate,
            NULLIF(TRIM(SOURCE.TransactionType), ''),
            SOURCE.PointsChange,
            NULLIF(TRIM(SOURCE.Description), ''),
            SOURCE.ServiceOfferingID,
            GETUTCDATE(),
            'OperationalDB'
        ); -- Mandatory Semicolon

END