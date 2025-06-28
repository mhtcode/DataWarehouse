-- Initial Load for DimAirlineAirportService
CREATE OR ALTER PROCEDURE [DW].[Initial_AirlineAirportService_Dim]
AS
BEGIN
  SET NOCOUNT ON;
  DECLARE
    @StartTime    DATETIME2(3) = SYSUTCDATETIME(),
    @RowsInserted INT,
    @LogID        BIGINT;

  INSERT INTO [DW].[ETL_Log] (ProcedureName, TargetTable, Status)
  VALUES ('Initial_AirlineAirportService_Dim','DimAirlineAirportService','Started');
  SET @LogID = SCOPE_IDENTITY();

  BEGIN TRY
    TRUNCATE TABLE [DW].[Temp_AirlineAirportService_table];

    INSERT INTO [DW].[Temp_AirlineAirportService_table] (
      ServiceTypeCode,
      FlightTypeCode,
      ServiceTypeName,
      FlightTypeName,
      ContractStartDate,
      ContractEndDate,
      LandingFeeRate,
      PassengerServiceRate
    )
    SELECT
      s.ServiceTypeCode,
      s.FlightTypeCode,
      s.ServiceTypeName,
      s.FlightTypeName,
      s.ContractStartDate,
      s.ContractEndDate,
      s.LandingFeeRate,
      s.PassengerServiceRate
    FROM [SA].[AirlineAirportService] AS s
    WHERE NOT EXISTS (
      SELECT 1 FROM [DW].[DimAirlineAirportService] AS d
      WHERE d.ServiceTypeCode = s.ServiceTypeCode
        AND d.FlightTypeCode = s.FlightTypeCode
    );
    SET @RowsInserted = @@ROWCOUNT;

    INSERT INTO [DW].[DimAirlineAirportService] (
      ServiceDimKey,
      ServiceTypeCode,
      FlightTypeCode,
      ServiceTypeName,
      FlightTypeName,
      ContractStartDate,
      ContractEndDate,
      LandingFeeRate,
      PassengerServiceRate
    )
    SELECT
      ROW_NUMBER() OVER (ORDER BY t.ServiceTypeCode, t.FlightTypeCode) + ISNULL(MAX(d.ServiceDimKey),0),
      t.ServiceTypeCode,
      t.FlightTypeCode,
      t.ServiceTypeName,
      t.FlightTypeName,
      t.ContractStartDate,
      t.ContractEndDate,
      t.LandingFeeRate,
      t.PassengerServiceRate
    FROM [DW].[Temp_AirlineAirportService_table] AS t
    LEFT JOIN [DW].[DimAirlineAirportService] AS d
      ON d.ServiceTypeCode = t.ServiceTypeCode
     AND d.FlightTypeCode = t.FlightTypeCode
    WHERE d.ServiceDimKey IS NULL
    GROUP BY
      t.ServiceTypeCode,
      t.FlightTypeCode,
      t.ServiceTypeName,
      t.FlightTypeName,
      t.ContractStartDate,
      t.ContractEndDate,
      t.LandingFeeRate,
      t.PassengerServiceRate;

    UPDATE [DW].[ETL_Log]
    SET ChangeDescription = 'Initial full load complete',
        RowsAffected = @RowsInserted,
        DurationSec  = DATEDIFF(SECOND,@StartTime,SYSUTCDATETIME()),
        Status       = 'Success'
    WHERE LogID = @LogID;

  END TRY
  BEGIN CATCH
    UPDATE [DW].[ETL_Log]
    SET ChangeDescription = 'Initial load failed',
        DurationSec       = DATEDIFF(SECOND,@StartTime,SYSUTCDATETIME()),
        Status            = 'Error',
        Message           = ERROR_MESSAGE()
    WHERE LogID = @LogID;
    THROW;
  END CATCH
END;
GO