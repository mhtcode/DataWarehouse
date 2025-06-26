CREATE OR ALTER PROCEDURE [SA].[ETL_PointConversionRate]
AS
BEGIN
    SET NOCOUNT ON;

    MERGE [SA].[PointConversionRate] AS TARGET
    USING [Source].[PointConversionRate] AS SOURCE
        ON (TARGET.PointConversionRateID = SOURCE.PointConversionRateID)

    -- Update if any relevant column changes
    WHEN MATCHED AND EXISTS (
        SELECT SOURCE.ConversionRate, SOURCE.CurrencyCode
        EXCEPT
        SELECT TARGET.ConversionRate, TARGET.CurrencyCode
    ) THEN
        UPDATE SET
            TARGET.ConversionRate = SOURCE.ConversionRate,
            TARGET.CurrencyCode = SOURCE.CurrencyCode,
            TARGET.StagingLastUpdateTimestampUTC = GETUTCDATE()

    -- Insert if not exists in SA
    WHEN NOT MATCHED BY TARGET THEN
        INSERT (
            PointConversionRateID,
            ConversionRate,
            CurrencyCode,
            StagingLoadTimestampUTC,
            SourceSystem
        )
        VALUES (
            SOURCE.PointConversionRateID,
            SOURCE.ConversionRate,
            SOURCE.CurrencyCode,
            GETUTCDATE(),
            'OperationalDB'
        );
END
GO
