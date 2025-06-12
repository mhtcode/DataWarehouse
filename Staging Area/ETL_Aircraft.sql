CREATE OR ALTER PROCEDURE [SA].[ETL_Aircraft]
AS
BEGIN
MERGE [SA].[Aircraft] AS TARGET
    USING [Source].[Aircraft] AS SOURCE
    ON (TARGET.AircraftID = SOURCE.AircraftID)

    -- Action for existing records that have changed
    WHEN MATCHED AND EXISTS (
        -- This clause correctly compares all relevant columns for any changes.
        SELECT SOURCE.Model, SOURCE.[Type], SOURCE.ManufacturerDate, SOURCE.Capacity, SOURCE.Price, SOURCE.AirlineID
        EXCEPT
        SELECT TARGET.Model, TARGET.[Type], TARGET.ManufacturerDate, TARGET.Capacity, TARGET.Price, TARGET.AirlineID
    ) THEN
        UPDATE SET
            TARGET.Model = NULLIF(TRIM(SOURCE.Model), ''),
            TARGET.[Type] = NULLIF(TRIM(SOURCE.[Type]), ''),
            TARGET.ManufacturerDate = SOURCE.ManufacturerDate,
            TARGET.Capacity = SOURCE.Capacity,
            TARGET.Price = SOURCE.Price,
            TARGET.AirlineID = SOURCE.AirlineID,
            TARGET.StagingLastUpdateTimestampUTC = GETUTCDATE()

    -- Action for new records
    WHEN NOT MATCHED BY TARGET THEN
        INSERT (
            AircraftID,
            Model,
            [Type],
            ManufacturerDate,
            Capacity,
            Price,
            AirlineID,
            StagingLoadTimestampUTC,
            SourceSystem
        )
        VALUES (
            SOURCE.AircraftID,
            NULLIF(TRIM(SOURCE.Model), ''),
            NULLIF(TRIM(SOURCE.[Type]), ''),
            SOURCE.ManufacturerDate,
            SOURCE.Capacity,
            SOURCE.Price,
            SOURCE.AirlineID,
            GETUTCDATE(),
            'OperationalDB'
        );
END

exec [SA].[ETL_Aircraft]

select * from [SA].[Aircraft]