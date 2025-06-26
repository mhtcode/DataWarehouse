CREATE OR ALTER PROCEDURE [SA].[ETL_ServiceOfferingItem]
AS
BEGIN
    SET NOCOUNT ON;

    MERGE [SA].[ServiceOfferingItem] AS TARGET
    USING [Source].[ServiceOfferingItem] AS SOURCE
        ON (
            TARGET.ServiceOfferingID = SOURCE.ServiceOfferingID AND
            TARGET.ItemID = SOURCE.ItemID
        )

    WHEN MATCHED AND (
            ISNULL(TARGET.Quantity, -1) <> ISNULL(SOURCE.Quantity, -1)
        )
        THEN UPDATE SET
            TARGET.Quantity = SOURCE.Quantity,
            TARGET.StagingLastUpdateTimestampUTC = GETUTCDATE(),
            TARGET.SourceSystem = 'OperationalDB'

    WHEN NOT MATCHED BY TARGET THEN
        INSERT (
            ServiceOfferingID,
            ItemID,
            Quantity,
            StagingLoadTimestampUTC,
            SourceSystem
        )
        VALUES (
            SOURCE.ServiceOfferingID,
            SOURCE.ItemID,
            SOURCE.Quantity,
            GETUTCDATE(),
            'OperationalDB'
        );
END
GO
