CREATE OR ALTER PROCEDURE [SA].[ETL_Airport]
AS
BEGIN
    MERGE [SA].[Airport] AS TARGET
    USING [Source].[Airport] AS SOURCE
    ON (TARGET.AirportID = SOURCE.AirportID)

    -- Action for existing records that have changed
    WHEN MATCHED AND EXISTS (
        -- This clause correctly compares all relevant columns for any changes.
        SELECT SOURCE.City, SOURCE.Country, SOURCE.IATACode, SOURCE.ElevationMeter, SOURCE.TimeZone, SOURCE.NumberOfTerminals, SOURCE.AnnualPassengerTraffic, SOURCE.Latitude, SOURCE.Longitude, SOURCE.ManagerName
        EXCEPT
        SELECT TARGET.City, TARGET.Country, TARGET.IATACode, TARGET.ElevationMeter, TARGET.TimeZone, TARGET.NumberOfTerminals, TARGET.AnnualPassengerTraffic, TARGET.Latitude, TARGET.Longitude, TARGET.ManagerName
    ) THEN
        UPDATE SET
            TARGET.City = NULLIF(TRIM(SOURCE.City), ''),
            TARGET.Country = NULLIF(TRIM(SOURCE.Country), ''),
            TARGET.IATACode = NULLIF(TRIM(SOURCE.IATACode), ''),
            TARGET.ElevationMeter = SOURCE.ElevationMeter,
            TARGET.TimeZone = NULLIF(TRIM(SOURCE.TimeZone), ''),
            TARGET.NumberOfTerminals = SOURCE.NumberOfTerminals,
            TARGET.AnnualPassengerTraffic = SOURCE.AnnualPassengerTraffic,
            TARGET.Latitude = SOURCE.Latitude,
            TARGET.Longitude = SOURCE.Longitude,
            TARGET.ManagerName = NULLIF(TRIM(SOURCE.ManagerName), ''),
            TARGET.StagingLastUpdateTimestampUTC = GETUTCDATE()

    -- Action for new records
    WHEN NOT MATCHED BY TARGET THEN
        INSERT (
            AirportID,
            City,
            Country,
            IATACode,
            ElevationMeter,
            TimeZone,
            NumberOfTerminals,
            AnnualPassengerTraffic,
            Latitude,
            Longitude,
            ManagerName,
            StagingLoadTimestampUTC,
            SourceSystem
        )
        VALUES (
            SOURCE.AirportID,
            NULLIF(TRIM(SOURCE.City), ''),
            NULLIF(TRIM(SOURCE.Country), ''),
            NULLIF(TRIM(SOURCE.IATACode), ''),
            SOURCE.ElevationMeter,
            NULLIF(TRIM(SOURCE.TimeZone), ''),
            SOURCE.NumberOfTerminals,
            SOURCE.AnnualPassengerTraffic,
            SOURCE.Latitude,
            SOURCE.Longitude,
            NULLIF(TRIM(SOURCE.ManagerName), ''),
            GETUTCDATE(),
            'OperationalDB'
        ); -- Mandatory Semicolon
END 