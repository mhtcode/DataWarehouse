CREATE OR ALTER PROCEDURE [DW].[Initial_Airport_Dim]
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE
    @StartTime    DATETIME2(3) = SYSUTCDATETIME(),
    @RowsInserted INT,
    @LogID        BIGINT;

  -- 1) Log procedure start
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
    -- 2) Truncate dimension table (optional: if you want a full reload)
    TRUNCATE TABLE DW.DimAirport;

    -- 3) Insert all airports from SA
    INSERT INTO DW.DimAirport (
      AirportID,
      City,
      Country,
      IATACode,
      ElevationMeter,
      TimeZone,
      NumberOfTerminals,
      AnnualPassengerTraffic,
      Latitude,
      Longitude
      -- , ManagerName
    )
    SELECT
      a.AirportID,
      a.City,
      a.Country,
      a.IATACode,
      a.ElevationMeter,
      a.TimeZone,
      a.NumberOfTerminals,
      a.AnnualPassengerTraffic,
      a.Latitude,
      a.Longitude
      -- , a.ManagerName
    FROM SA.Airport AS a;

    SET @RowsInserted = @@ROWCOUNT;

    -- 4) Mark log as success
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
    -- 5) Log error
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