CREATE OR ALTER PROCEDURE [SA].[ETL_ServiceOffering]
AS
BEGIN
    SET NOCOUNT ON;

    MERGE [SA].[ServiceOffering] AS TARGET
    USING [Source].[ServiceOffering] AS SOURCE
        ON (TARGET.ServiceOfferingID = SOURCE.ServiceOfferingID)

    -- Update if any significant column changed
    WHEN MATCHED AND (
            ISNULL(TARGET.TravelClassID, -1)         <> ISNULL(SOURCE.TravelClassID, -1)
         OR ISNULL(TARGET.OfferingName, '')          <> ISNULL(LTRIM(RTRIM(SOURCE.OfferingName)), '')
         OR ISNULL(TARGET.Description, '')           <> ISNULL(LTRIM(RTRIM(SOURCE.Description)), '')
         OR ISNULL(TARGET.TotalCost, -1)             <> ISNULL(SOURCE.TotalCost, -1)
        )
        THEN UPDATE SET
            TARGET.TravelClassID = SOURCE.TravelClassID,
            TARGET.OfferingName  = NULLIF(LTRIM(RTRIM(SOURCE.OfferingName)), ''),
            TARGET.Description   = NULLIF(LTRIM(RTRIM(SOURCE.Description)), ''),
            TARGET.TotalCost     = SOURCE.TotalCost,
            TARGET.StagingLastUpdateTimestampUTC = GETUTCDATE(),
            TARGET.SourceSystem = 'OperationalDB'
    
    -- Insert new records
    WHEN NOT MATCHED BY TARGET THEN
        INSERT (
            ServiceOfferingID,
            TravelClassID,
            OfferingName,
            Description,
            TotalCost,
            StagingLoadTimestampUTC,
            StagingLastUpdateTimestampUTC,
            SourceSystem
        )
        VALUES (
            SOURCE.ServiceOfferingID,
            SOURCE.TravelClassID,
            NULLIF(LTRIM(RTRIM(SOURCE.OfferingName)), ''),
            NULLIF(LTRIM(RTRIM(SOURCE.Description)), ''),
            SOURCE.TotalCost,
            GETUTCDATE(),
            GETUTCDATE(),
            'OperationalDB'
        );

END
GO
