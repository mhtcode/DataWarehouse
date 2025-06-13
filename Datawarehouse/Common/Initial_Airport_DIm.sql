CREATE OR ALTER PROCEDURE [DW].[Initial_Airport_Dim]
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE
    @StartTime    DATETIME2(3) = SYSUTCDATETIME(),
    @RowsInserted INT,
    @LogID        BIGINT;

  -- 1) Assume fatal: insert initial log entry
  INSERT INTO DW.ETL_Log (
    ProcedureName, TargetTable, ChangeDescription, ActionTime, Status
  ) VALUES (
    'Initial_Airport_Dim',
    'DimAirport',
    'Procedure started - awaiting completion',
    @StartTime,
    'Fatal'
  );
  SET @LogID = SCOPE_IDENTITY();

  BEGIN TRY
    -- 2) Insert new airports into dimension directly
    INSERT INTO DW.DimAirport (
      AirportKey, Name, City, Country,
      IATACode, ElevationMeter, TimeZone,
      NumberOfTerminals, AnnualPassengerTraffic,
      Latitude, Longitude
    )
    SELECT
      a.AirportID,
      a.Name,
      a.City,
      a.Country,
      a.IATACode,
      a.ElevationMeter,
      a.TimeZone,
      a.NumberOfTerminals,
      a.AnnualPassengerTraffic,
      a.Latitude,
      a.Longitude
    FROM SA.Airport AS a
    WHERE NOT EXISTS (
      SELECT 1 FROM DW.DimAirport AS d WHERE d.AirportKey = a.AirportID
    );
    SET @RowsInserted = @@ROWCOUNT;

    -- 3) Update log entry to Success
    UPDATE DW.ETL_Log
    SET
      ChangeDescription = 'Initial full load complete',
      RowsAffected      = @RowsInserted,
      DurationSec       = DATEDIFF(SECOND, @StartTime, SYSUTCDATETIME()),
      Status            = 'Success'
    WHERE LogID = @LogID;

  END TRY
  BEGIN CATCH
    DECLARE @ErrMsg NVARCHAR(MAX) = ERROR_MESSAGE();
    -- 4) Update log entry to Error
    UPDATE DW.ETL_Log
    SET
      ChangeDescription = 'Initial load failed',
      DurationSec       = DATEDIFF(SECOND, @StartTime, SYSUTCDATETIME()),
      Status            = 'Error',
      Message           = @ErrMsg
    WHERE LogID = @LogID;
    THROW;
  END CATCH
END;
GO