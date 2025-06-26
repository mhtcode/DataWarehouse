CREATE OR ALTER PROCEDURE [SA].[ETL_TravelClass]
AS
BEGIN
    SET NOCOUNT ON;

    MERGE [SA].[TravelClass] AS TARGET
    USING [Source].[TravelClass] AS SOURCE
    ON (TARGET.TravelClassID = SOURCE.TravelClassID)

    -- Update existing records if any field has changed (SCD1)
    WHEN MATCHED AND EXISTS (
        SELECT
            SOURCE.ClassName,
            SOURCE.Capacity,
            SOURCE.BaseCost
        EXCEPT
        SELECT
            TARGET.ClassName,
            TARGET.Capacity,
            TARGET.BaseCost
    ) THEN
        UPDATE SET
            TARGET.ClassName = NULLIF(LTRIM(RTRIM(SOURCE.ClassName)), ''),
            TARGET.Capacity = SOURCE.Capacity,
            TARGET.BaseCost = SOURCE.BaseCost,
            TARGET.StagingLastUpdateTimestampUTC = GETUTCDATE()

    -- Insert new records
    WHEN NOT MATCHED BY TARGET THEN
        INSERT (
            TravelClassID,
            ClassName,
            Capacity,
            BaseCost,
            StagingLoadTimestampUTC,
            SourceSystem
        )
        VALUES (
            SOURCE.TravelClassID,
            NULLIF(LTRIM(RTRIM(SOURCE.ClassName)), ''),
            SOURCE.Capacity,
            SOURCE.BaseCost,
            GETUTCDATE(),
            'OperationalDB'
        );

END
GO
