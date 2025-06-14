CREATE OR ALTER PROCEDURE [DW].[ETL_Flight_Dim]
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
    'ETL_Flight_Dim',
    'DimFlight',
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
    WHERE ProcedureName = 'ETL_Flight_Dim'
      AND Status = 'Success';

    -- 3) Truncate staging
    TRUNCATE TABLE [DW].[Temp_Flight_table];

    -- 4) Populate staging with changed/new flights
    INSERT INTO [DW].[Temp_Flight_table] (
      FlightID,
      DepartureDateTime,
      ArrivalDateTime,
      FlightDurationMinutes,
      AircraftKey,
      FlightCapacity,
      TotalCost
    )
    SELECT
      a.FlightDetailID,
      a.DepartureDateTime,
      a.ArrivalDateTime,
      (DATEDIFF(minute, a.DepartureDateTime, a.ArrivalDateTime)),
      a.AircraftID,
      a.FlightCapacity,
      a.TotalCost
    FROM SA.FlightDetail AS a
    WHERE a.StagingLastUpdateTimestampUTC > @LastRunTime;

    -- 5) Update existing accounts in dimension
    UPDATE d
    SET
      d.FlightKey = t.FlightID,
      d.DepartureDateTime = t.DepartureDateTime,
      d.ArrivalDateTime = t.ArrivalDateTime,
      d.FlightDurationMinutes = t.FlightDurationMinutes,
      d.AircraftKey = t.AircraftKey,
      d.FlightCapacity = t.FlightCapacity,
      d.TotalCost = t.TotalCost    
    FROM DW.DimFlight AS d
    JOIN DW.Temp_Flight_table AS t
      ON d.FlightKey = t.FlightID;
    SET @RowsUpdated = @@ROWCOUNT;

    -- 6) Insert new accounts into dimension
    INSERT INTO DW.DimFlight (
      FlightKey,
      DepartureDateTime,
      ArrivalDateTime,
      FlightDurationMinutes,
      AircraftKey,
      FlightCapacity,
      TotalCost
    )
    SELECT
      t.FlightID,
      t.DepartureDateTime,
      t.ArrivalDateTime,
      t.FlightDurationMinutes,
      t.AircraftKey,
      t.FlightCapacity,
      t.TotalCost
    FROM DW.Temp_Flight_table AS t
    WHERE NOT EXISTS (
      SELECT 1 FROM DW.DimFlight AS d
      WHERE d.FlightKey = t.FlightID
    );
    SET @RowsInserted = @@ROWCOUNT;

    -- 7) Update log entry to Success
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
    -- 8) Update log entry to Error
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