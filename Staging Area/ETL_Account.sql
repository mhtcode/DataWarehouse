CREATE OR ALTER PROCEDURE [SA].[ETL_Account]
AS
BEGIN       
    MERGE [SA].[Account] AS TARGET
    USING [Source].[Account] AS SOURCE
    ON (TARGET.AccountID = SOURCE.AccountID)

    -- Action for existing records that have changed
    WHEN MATCHED AND EXISTS (
        -- This clause correctly compares all relevant columns for any changes.
        SELECT SOURCE.PassengerID, SOURCE.RegistrationDate, SOURCE.LoyaltyTierID
        EXCEPT
        SELECT TARGET.PassengerID, TARGET.RegistrationDate, TARGET.LoyaltyTierID
    ) THEN
        UPDATE SET
            TARGET.PassengerID = SOURCE.PassengerID,
            TARGET.RegistrationDate = SOURCE.RegistrationDate,
            TARGET.LoyaltyTierID = SOURCE.LoyaltyTierID,
            TARGET.StagingLastUpdateTimestampUTC = GETUTCDATE()

    -- Action for new records
    WHEN NOT MATCHED BY TARGET THEN
        INSERT (
            AccountID,
            PassengerID,
            RegistrationDate,
            LoyaltyTierID,
            StagingLoadTimestampUTC,
            SourceSystem
        )
        VALUES (
            SOURCE.AccountID,
            SOURCE.PassengerID,
            SOURCE.RegistrationDate,
            SOURCE.LoyaltyTierID,
            GETUTCDATE(),
            'OperationalDB'
        ); -- Mandatory Semicolon
END

exec [SA].[ETL_Account]