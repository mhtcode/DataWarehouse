CREATE OR ALTER PROCEDURE [SA].[ETL_LoyaltyTier]
AS
BEGIN
    MERGE [SA].[LoyaltyTier] AS TARGET
    USING [Source].[LoyaltyTier] AS SOURCE
    ON (TARGET.LoyaltyTierID = SOURCE.LoyaltyTierID)

    -- Action for existing records that have changed
    WHEN MATCHED AND EXISTS (
        -- This clause correctly compares all relevant columns for any changes.
        SELECT SOURCE.Name, SOURCE.MinPoints, SOURCE.Benefits
        EXCEPT
        SELECT TARGET.Name, TARGET.MinPoints, TARGET.Benefits
    ) THEN
        UPDATE SET
            TARGET.Name = NULLIF(TRIM(SOURCE.Name), ''),
            TARGET.MinPoints = SOURCE.MinPoints,
            TARGET.Benefits = NULLIF(TRIM(SOURCE.Benefits), ''),
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
        )
        VALUES (
            SOURCE.LoyaltyTierID,
            NULLIF(TRIM(SOURCE.Name), ''),
            SOURCE.MinPoints,
            NULLIF(TRIM(SOURCE.Benefits), ''),
            GETUTCDATE(),
            'OperationalDB'
        ); -- Mandatory Semicolon

END