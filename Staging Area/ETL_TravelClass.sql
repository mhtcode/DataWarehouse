CREATE OR ALTER PROCEDURE [SA].[ETL_TravelClass]
AS
BEGIN
    MERGE [SA].[TravelClass] AS TARGET
    USING [Source].[TravelClass] AS SOURCE
    ON (TARGET.TravelClassID = SOURCE.TravelClassID)

    -- Action for existing records that have changed
    WHEN MATCHED AND EXISTS (
        -- This clause correctly compares all relevant columns for any changes.
        SELECT SOURCE.Name, SOURCE.Capacity, SOURCE.Cost
        EXCEPT
        SELECT TARGET.Name, TARGET.Capacity, TARGET.Cost
    ) THEN
        UPDATE SET
            TARGET.Name = NULLIF(TRIM(SOURCE.Name), ''),
            TARGET.Capacity = SOURCE.Capacity,
            TARGET.Cost = SOURCE.Cost,
            TARGET.StagingLastUpdateTimestampUTC = GETUTCDATE()

    -- Action for new records
    WHEN NOT MATCHED BY TARGET THEN
        INSERT (
            TravelClassID,
            Name,
            Capacity,
            Cost,
            StagingLoadTimestampUTC,
            SourceSystem
        )
        VALUES (
            SOURCE.TravelClassID,
            NULLIF(TRIM(SOURCE.Name), ''),
            SOURCE.Capacity,
            SOURCE.Cost,
            GETUTCDATE(),
            'OperationalDB'
        ); -- Mandatory Semicolon

END