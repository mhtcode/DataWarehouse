CREATE OR ALTER PROCEDURE [DW].[ETL_Airport_Dim]
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE
    @StartTime     DATETIME2(3) = SYSUTCDATETIME(),
    @LastRunTime   DATETIME2(3),
    @RowsUpdated   INT,
    @RowsInserted  INT,
    @LogID         BIGINT;

  -- 1) Assume fatal: insert initial log entry
  INSERT INTO DW.ETL_Log (
    ProcedureName, TargetTable, ChangeDescription, ActionTime, Status
  ) VALUES (
    'ETL_Airport_Dim',
    'DimAirport',
    'Procedure started - awaiting completion',
    @StartTime,
    'Fatal'
  );
  SET @LogID = SCOPE_IDENTITY();

  BEGIN TRY
    -- 2) Determine last successful run time
    SELECT
      @LastRunTime = COALESCE(
        MAX(ActionTime),
        '1900-01-01'
      )
    FROM DW.ETL_Log
    WHERE ProcedureName = 'ETL_Airport_Dim'
      AND Status = 'Success';

    -- 3) Truncate staging
    TRUNCATE TABLE [DW].[Temp_Airport_table];

    -- 4) Populate staging with changed/new airports
    INSERT INTO [DW].[Temp_Airport_table] (
      AirportID, Name, City, Country,
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
    WHERE a.StagingLastUpdateTimestampUTC > @LastRunTime;

    -- 5) Update existing airports in dimension
    UPDATE d
    SET
      d.Name                   = t.Name,
      d.City                   = t.City,
      d.Country                = t.Country,
      d.IATACode               = t.IATACode,
      d.ElevationMeter         = t.ElevationMeter,
      d.TimeZone               = t.TimeZone,
      d.NumberOfTerminals      = t.NumberOfTerminals,
      d.AnnualPassengerTraffic = t.AnnualPassengerTraffic,
      d.Latitude               = t.Latitude,
      d.Longitude              = t.Longitude
    FROM DW.DimAirport AS d
    JOIN DW.Temp_Airport_table AS t
      ON d.AirportKey = t.AirportID;
    SET @RowsUpdated = @@ROWCOUNT;

    -- 6) Insert new airports into dimension
    INSERT INTO DW.DimAirport (
      AirportKey, Name, City, Country,
      IATACode, ElevationMeter, TimeZone,
      NumberOfTerminals, AnnualPassengerTraffic,
      Latitude, Longitude
    )
    SELECT
      t.AirportID,
      t.Name,
      t.City,
      t.Country,
      t.IATACode,
      t.ElevationMeter,
      t.TimeZone,
      t.NumberOfTerminals,
      t.AnnualPassengerTraffic,
      t.Latitude,
      t.Longitude
    FROM DW.Temp_Airport_table AS t
    WHERE NOT EXISTS (
      SELECT 1
      FROM DW.DimAirport AS d
      WHERE d.AirportKey = t.AirportID
    );
    SET @RowsInserted = @@ROWCOUNT;

    -- 7) Update log to Success
    UPDATE DW.ETL_Log
    SET
      ChangeDescription = CONCAT(
        'Incremental load complete: updated=', @RowsUpdated,
        ', inserted=', @RowsInserted
      ),
      RowsAffected      = @RowsUpdated + @RowsInserted,
      DurationSec       = DATEDIFF(SECOND, @StartTime, SYSUTCDATETIME()),
      Status            = 'Success'
    WHERE LogID = @LogID;

  END TRY
  BEGIN CATCH
    DECLARE @ErrMsg NVARCHAR(MAX) = ERROR_MESSAGE();
    -- 8) Update log to Error
    UPDATE DW.ETL_Log
    SET
      ChangeDescription = 'Incremental load failed',
      DurationSec       = DATEDIFF(SECOND, @StartTime, SYSUTCDATETIME()),
      Status            = 'Error',
      Message           = @ErrMsg
    WHERE LogID = @LogID;
    THROW;
  END CATCH
END;
GO