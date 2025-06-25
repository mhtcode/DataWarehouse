CREATE OR ALTER PROCEDURE [SA].[ETL_AirlineAirportService]
AS
BEGIN
    MERGE [SA].[AirlineAirportService] AS TARGET
    USING [Source].[AirlineAirportService] AS SOURCE
      ON TARGET.ServiceTypeCode = SOURCE.ServiceTypeCode
     AND TARGET.FlightTypeCode = SOURCE.FlightTypeCode

    -- 1) UPDATE existing rows when *any* source column changed
    WHEN MATCHED AND EXISTS (
        SELECT
            SOURCE.ServiceTypeName,
            SOURCE.FlightTypeName,
            SOURCE.ContractStartDate,
            SOURCE.ContractEndDate,
            SOURCE.LandingFeeRate,
            SOURCE.PassengerServiceRate
        EXCEPT
        SELECT
            TARGET.ServiceTypeName,
            TARGET.FlightTypeName,
            TARGET.ContractStartDate,
            TARGET.ContractEndDate,
            TARGET.LandingFeeRate,
            TARGET.PassengerServiceRate
    )
    THEN
      UPDATE SET
        TARGET.ServiceTypeName              = NULLIF(TRIM(SOURCE.ServiceTypeName), ''),
        TARGET.FlightTypeName               = NULLIF(TRIM(SOURCE.FlightTypeName), ''),
        TARGET.ContractStartDate            = SOURCE.ContractStartDate,
        TARGET.ContractEndDate              = SOURCE.ContractEndDate,
        TARGET.LandingFeeRate               = SOURCE.LandingFeeRate,
        TARGET.PassengerServiceRate         = SOURCE.PassengerServiceRate,
        TARGET.StagingLastUpdateTimestampUTC = GETUTCDATE()

    -- 2) INSERT brand-new records
    WHEN NOT MATCHED BY TARGET
    THEN
      INSERT (
        ServiceTypeCode,
        FlightTypeCode,
        ServiceTypeName,
        FlightTypeName,
        ContractStartDate,
        ContractEndDate,
        LandingFeeRate,
        PassengerServiceRate,
        StagingLoadTimestampUTC,
        SourceSystem
      )
      VALUES (
        SOURCE.ServiceTypeCode,
        SOURCE.FlightTypeCode,
        NULLIF(TRIM(SOURCE.ServiceTypeName), ''),
        NULLIF(TRIM(SOURCE.FlightTypeName), ''),
        SOURCE.ContractStartDate,
        SOURCE.ContractEndDate,
        SOURCE.LandingFeeRate,
        SOURCE.PassengerServiceRate,
        GETUTCDATE(),
        'OperationalDB'
      );
END;
GO

