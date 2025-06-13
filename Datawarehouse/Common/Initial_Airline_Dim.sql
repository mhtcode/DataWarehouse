CREATE OR ALTER PROCEDURE [DW].[Initial_Airline_Dim]
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
    'Initial_Airline_Dim',
    'DimAirline',
    'Procedure started - awaiting completion',
    @StartTime,
    'Fatal'
  );
  SET @LogID = SCOPE_IDENTITY();

  BEGIN TRY
    -- 2) Load all airlines into DimAirline
    INSERT INTO DW.DimAirline (
      AirlineKey, Name, Country, FoundedYear,
      FleetSize, Website, EffectiveFrom,
      EffectiveTo, FleetSizeIsCurrent
    )
    SELECT
      a.AirlineID,
      a.Name,
      a.Country,
      a.FoundedYear,
      a.FleetSize,
      a.Website,
      @StartTime,
      NULL,
      1
    FROM SA.Airline AS a
    WHERE NOT EXISTS (
      SELECT 1
      FROM DW.DimAirline AS d
      WHERE d.AirlineKey = a.AirlineID
    );
    SET @RowsInserted = @@ROWCOUNT;

    -- 3) Update log to Success
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
    -- 4) Update log to Error
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