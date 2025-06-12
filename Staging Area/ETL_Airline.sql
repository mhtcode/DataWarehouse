CREATE OR ALTER PROCEDURE [SA].[ETL_Airline]
AS
BEGIN
    MERGE [SA].[Airline] AS TARGET
    USING [Source].[Airline] AS SOURCE
    ON (TARGET.AirlineID = SOURCE.AirlineID)

    -- Action for existing records that have changed
    WHEN MATCHED AND EXISTS (
        -- This clause correctly compares all relevant columns for any changes.
        SELECT SOURCE.Name, SOURCE.Country, SOURCE.FoundedDate, SOURCE.HeadquartersNumber, SOURCE.FleetSize, SOURCE.Website
        EXCEPT
        SELECT TARGET.Name, TARGET.Country, TARGET.FoundedDate, TARGET.HeadquartersNumber, TARGET.FleetSize, TARGET.Website
    ) THEN
        UPDATE SET
            TARGET.Name = NULLIF(TRIM(SOURCE.Name), ''),
            TARGET.Country = NULLIF(TRIM(SOURCE.Country), ''),
            TARGET.FoundedDate = SOURCE.FoundedDate,
            TARGET.HeadquartersNumber = NULLIF(TRIM(SOURCE.HeadquartersNumber), ''),
            TARGET.FleetSize = SOURCE.FleetSize,
            TARGET.Website = NULLIF(TRIM(SOURCE.Website), ''),
            TARGET.StagingLastUpdateTimestampUTC = GETUTCDATE()

    -- Action for new records
    WHEN NOT MATCHED BY TARGET THEN
        INSERT (
            AirlineID,
            Name,
            Country,
            FoundedDate,
            HeadquartersNumber,
            FleetSize,
            Website,
            StagingLoadTimestampUTC,
            SourceSystem
        )
        VALUES (
            SOURCE.AirlineID,
            NULLIF(TRIM(SOURCE.Name), ''),
            NULLIF(TRIM(SOURCE.Country), ''),
            SOURCE.FoundedDate,
            NULLIF(TRIM(SOURCE.HeadquartersNumber), ''),
            SOURCE.FleetSize,
            NULLIF(TRIM(SOURCE.Website), ''),
            GETUTCDATE(),
            'OperationalDB'
        ); -- Mandatory Semicolon
END

exec [SA].[ETL_Airline]

select * from [SA].[Airline]