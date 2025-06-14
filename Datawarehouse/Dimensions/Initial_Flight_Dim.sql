CREATE OR ALTER PROCEDURE [DW].[Initial_Flightt_Dim]
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE
    @StartTime     DATETIME2(3) = SYSUTCDATETIME(),
    @RowsInserted  INT,
    @LogID         BIGINT;

  -- 1) Assume fatal: insert initial log entry
  INSERT INTO DW.ETL_Log (
    ProcedureName, TargetTable, ChangeDescription, ActionTime, Status
  ) VALUES (
    'Initial_Flight_Dim',
    'DimFlight',
    'Procedure started - awaiting completion',
    @StartTime,
    'Fatal'
  );
  SET @LogID = SCOPE_IDENTITY();

  BEGIN TRY
    -- 2) Insert all new flights into dimension
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
      a.FlightDetailID,
      a.DepartureDateTime,
      a.ArrivalDateTime,
      (DATEDIFF(minute, a.DepartureDateTime, a.ArrivalDateTime)),
      a.AircraftKey,
      a.FlightCapacity,
      a.TotalCost
    FROM SA.FlightDetail AS a
    WHERE NOT EXISTS (
      SELECT 1 FROM DW.DimFlight AS d
      WHERE d.FlightKey = a.FlightDetailID
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
