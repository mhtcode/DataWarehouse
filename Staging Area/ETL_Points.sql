CREATE OR ALTER PROCEDURE [SA].[ETL_Points]
AS
BEGIN
    MERGE [SA].[Points] AS TARGET
    USING [Source].[Points] AS SOURCE
    ON (TARGET.PointsID = SOURCE.PointsID)

    -- Action for existing records that have changed
    WHEN MATCHED AND EXISTS (
        -- This clause correctly compares all relevant columns for any changes.
        SELECT SOURCE.AccountID, SOURCE.PointsBalance, SOURCE.EffectiveDate
        EXCEPT
        SELECT TARGET.AccountID, TARGET.PointsBalance, TARGET.EffectiveDate
    ) THEN
        UPDATE SET
            TARGET.AccountID = SOURCE.AccountID,
            TARGET.PointsBalance = SOURCE.PointsBalance,
            TARGET.EffectiveDate = SOURCE.EffectiveDate,
            TARGET.StagingLastUpdateTimestampUTC = GETUTCDATE()

    -- Action for new records
    WHEN NOT MATCHED BY TARGET THEN
        INSERT (
            PointsID,
            AccountID,
            PointsBalance,
            EffectiveDate,
            StagingLoadTimestampUTC,
            SourceSystem
        )
        VALUES (
            SOURCE.PointsID,
            SOURCE.AccountID,
            SOURCE.PointsBalance,
            SOURCE.EffectiveDate,
            GETUTCDATE(),
            'OperationalDB'
        ); -- Mandatory Semicolon

END