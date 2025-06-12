CREATE OR ALTER PROCEDURE [SA].[ETL_ServiceOffering]
AS
BEGIN
    MERGE [SA].[ServiceOffering] AS TARGET
    USING [Source].[ServiceOffering] AS SOURCE
    ON (TARGET.ServiceOfferingID = SOURCE.ServiceOfferingID)

    -- Action for existing records that have changed
    WHEN MATCHED AND EXISTS (
        -- This clause correctly compares all relevant columns for any changes.
        SELECT SOURCE.TravelClassID, SOURCE.Name, SOURCE.Cost
        EXCEPT
        SELECT TARGET.TravelClassID, TARGET.Name, TARGET.Cost
    ) THEN
        UPDATE SET
            TARGET.TravelClassID = SOURCE.TravelClassID,
            TARGET.Name = NULLIF(TRIM(SOURCE.Name), ''),
            TARGET.Cost = SOURCE.Cost,
            TARGET.StagingLastUpdateTimestampUTC = GETUTCDATE()

    -- Action for new records
    WHEN NOT MATCHED BY TARGET THEN
        INSERT (
            ServiceOfferingID,
            TravelClassID,
            Name,
            Cost,
            StagingLoadTimestampUTC,
            SourceSystem
        )
        VALUES (
            SOURCE.ServiceOfferingID,
            SOURCE.TravelClassID,
            NULLIF(TRIM(SOURCE.Name), ''),
            SOURCE.Cost,
            GETUTCDATE(),
            'OperationalDB'
        ); -- Mandatory Semicolon

END