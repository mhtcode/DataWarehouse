CREATE OR ALTER PROCEDURE [SA].[ETL_AccountTierHistory]
AS
BEGIN 
    MERGE [SA].[AccountTierHistory] AS TARGET
    USING [Source].[AccountTierHistory] AS SOURCE
    ON (TARGET.HistoryID = SOURCE.HistoryID)

    -- Action for existing records that have changed
    WHEN MATCHED AND EXISTS (
        -- This clause correctly compares all relevant columns for any changes.
        SELECT SOURCE.HistoryID, SOURCE.AccountID, SOURCE.LoyaltyTierID, SOURCE.EffectiveFrom, SOURCE.EffectiveTo, SOURCE.CurrentFlag
        EXCEPT
        SELECT TARGET.HistoryID, TARGET.AccountID, TARGET.LoyaltyTierID, TARGET.EffectiveFrom, TARGET.EffectiveTo, TARGET.CurrentFlag
    ) THEN
        UPDATE SET
            TARGET.HistoryID = SOURCE.HistoryID,
            TARGET.AccountID = SOURCE.AccountID,
            TARGET.LoyaltyTierID = SOURCE.LoyaltyTierID,
            TARGET.EffectiveFrom = SOURCE.EffectiveFrom,
            TARGET.EffectiveTo = SOURCE.EffectiveTo,
            TARGET.CurrentFlag = SOURCE.CurrentFlag,
            TARGET.StagingLastUpdateTimestampUTC = GETUTCDATE()

    -- Action for new records
    WHEN NOT MATCHED BY TARGET THEN
        INSERT (    
            HistoryID,
            AccountID,
            LoyaltyTierID,
            EffectiveFrom,
            EffectiveTo,
            CurrentFlag,
            StagingLoadTimestampUTC,
            SourceSystem
        )
        VALUES (
            SOURCE.HistoryID,
            SOURCE.AccountID,
            SOURCE.LoyaltyTierID,
            SOURCE.EffectiveFrom,
            SOURCE.EffectiveTo,
            SOURCE.CurrentFlag,
            GETUTCDATE(),
            'OperationalDB'
        ); -- Mandatory Semicolon

END
