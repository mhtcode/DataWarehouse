CREATE OR ALTER PROCEDURE [SA].[ETL_Passenger]
AS
BEGIN
	MERGE [SA].[Passenger] AS TARGET
        USING [Source].[Passenger] AS SOURCE
        ON (TARGET.PassengerID = SOURCE.PassengerID)

        -- Action for existing records that have changed
        WHEN MATCHED AND EXISTS (
            -- This clause correctly compares all relevant columns for any changes.
            SELECT SOURCE.PersonID, SOURCE.PassportNumber
            EXCEPT
            SELECT TARGET.PersonID, TARGET.PassportNumber
        ) THEN
            UPDATE SET
                TARGET.PersonID = SOURCE.PersonID,
                TARGET.PassportNumber = NULLIF(TRIM(SOURCE.PassportNumber), ''),
                TARGET.StagingLastUpdateTimestampUTC = GETUTCDATE()

        -- Action for new records
        WHEN NOT MATCHED BY TARGET THEN
            INSERT (
                PassengerID,
                PersonID,
                PassportNumber,
                StagingLoadTimestampUTC,
                SourceSystem
            )
            VALUES (
                SOURCE.PassengerID,
                SOURCE.PersonID,
                NULLIF(TRIM(SOURCE.PassportNumber), ''),
                GETUTCDATE(),
                'OperationalDB'
            ); -- Mandatory Semicolon

END
