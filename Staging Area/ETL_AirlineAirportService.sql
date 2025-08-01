CREATE OR ALTER PROCEDURE [SA].[ETL_AirlineAirportService]
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE
        @StartTime     DATETIME2(3) = SYSUTCDATETIME(),
        @RowsAffected  INT,
        @LogID         BIGINT;

    INSERT INTO [SA].[ETL_Log] (
        ProcedureName,
        SourceTable,
        TargetTable,
        ChangeDescription,
        ActionTime,
        Status
    ) VALUES (
        'ETL_AirlineAirportService',
        'Source.AirlineAirportService',
        'SA.AirlineAirportService',
        'Procedure started - awaiting completion',
        @StartTime,
        'Fatal'
    );
    SET @LogID = SCOPE_IDENTITY();

    BEGIN TRY
        MERGE [SA].[AirlineAirportService] AS TARGET
        USING [Source].[AirlineAirportService] AS SOURCE
          ON TARGET.ServiceTypeCode = SOURCE.ServiceTypeCode
         AND TARGET.FlightTypeCode  = SOURCE.FlightTypeCode

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
        ) THEN
            UPDATE SET
                TARGET.ServiceTypeName              = NULLIF(TRIM(SOURCE.ServiceTypeName), ''),
                TARGET.FlightTypeName               = NULLIF(TRIM(SOURCE.FlightTypeName), ''),
                TARGET.ContractStartDate            = SOURCE.ContractStartDate,
                TARGET.ContractEndDate              = SOURCE.ContractEndDate,
                TARGET.LandingFeeRate               = SOURCE.LandingFeeRate,
                TARGET.PassengerServiceRate         = SOURCE.PassengerServiceRate,
                TARGET.StagingLastUpdateTimestampUTC = GETUTCDATE()

        WHEN NOT MATCHED BY TARGET THEN
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
            ) VALUES (
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

        SET @RowsAffected = @@ROWCOUNT;

        UPDATE [SA].[ETL_Log]
        SET
            ChangeDescription = CONCAT('Merge complete: rows affected=', @RowsAffected),
            RowsAffected      = @RowsAffected,
            DurationSec       = DATEDIFF(SECOND, @StartTime, SYSUTCDATETIME()),
            Status            = 'Success'
        WHERE LogID = @LogID;

    END TRY
    BEGIN CATCH
        UPDATE [SA].[ETL_Log]
        SET
            ChangeDescription = 'Merge failed',
            DurationSec       = DATEDIFF(SECOND, @StartTime, SYSUTCDATETIME()),
            Status            = 'Error',
            Message           = ERROR_MESSAGE()
        WHERE LogID = @LogID;
        THROW;
    END CATCH
END;
GO
