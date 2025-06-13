CREATE OR ALTER PROCEDURE [DW].[ETL_Airline_Dim]
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE
    @StartTime      DATETIME2(3) = SYSUTCDATETIME(),
    @LastRunTime    DATETIME2(3),
    @RowsExpired    INT,
    @RowsInserted   INT,
    @LogID          BIGINT;

  -- 1) Assume fatal: insert initial log entry
  INSERT INTO DW.ETL_Log (
    ProcedureName, TargetTable, ChangeDescription, ActionTime, Status
  ) VALUES (
    'ETL_Airline_Dim',
    'DimAirline',
    'Procedure started - awaiting completion',
    @StartTime,
    'Fatal'
  );
  SET @LogID = SCOPE_IDENTITY();

  BEGIN TRY
    -- 2) Determine last successful run time
    SELECT @LastRunTime = COALESCE(
      MAX(ActionTime),
      '1900-01-01'
    )
    FROM DW.ETL_Log
    WHERE ProcedureName = 'ETL_Airline_Dim'
      AND Status = 'Success';

    -- 3) Truncate staging
    TRUNCATE TABLE [DW].[Temp_Airline_table];

    -- 4) Populate staging with new/changed rows
    INSERT INTO [DW].[Temp_Airline_table] (
      AirlineID, Name, Country,
      FoundedYear, FleetSize, Website
    )
    SELECT
      a.AirlineID,
      a.Name,
      a.Country,
      a.FoundedYear,
      a.FleetSize,
      a.Website
    FROM SA.Airline AS a
    WHERE a.StagingLastUpdateTimestampUTC > @LastRunTime;

    -- 5) Expire old current versions for changed keys
    UPDATE d
    SET
      d.FleetSizeIsCurrent = 0,
      d.EffectiveTo        = @StartTime
    FROM DW.DimAirline AS d
    JOIN DW.Temp_Airline_table AS t
      ON d.AirlineKey = t.AirlineID
    WHERE d.FleetSizeIsCurrent = 1
      AND (
        ISNULL(d.Name,'')         <> ISNULL(t.Name,'')
        OR ISNULL(d.Country,'')    <> ISNULL(t.Country,'')
        OR ISNULL(d.FoundedYear,0) <> ISNULL(t.FoundedYear,0)
        OR ISNULL(d.FleetSize,0)   <> ISNULL(t.FleetSize,0)
        OR ISNULL(d.Website,'')     <> ISNULL(t.Website,'')
      );
    SET @RowsExpired = @@ROWCOUNT;

    -- 6) Insert new versions for changed/ new keys
    INSERT INTO DW.DimAirline (
      AirlineKey, Name, Country,
      FoundedYear, FleetSize, Website,
      EffectiveFrom, EffectiveTo, FleetSizeIsCurrent
    )
    SELECT
      t.AirlineID,
      t.Name,
      t.Country,
      t.FoundedYear,
      t.FleetSize,
      t.Website,
      @StartTime,
      NULL,
      1
    FROM DW.Temp_Airline_table AS t;
    SET @RowsInserted = @@ROWCOUNT;

    -- 7) Update log to Success
    UPDATE DW.ETL_Log
    SET
      ChangeDescription = CONCAT(
        'Incremental SCD2 load complete: expired=',@RowsExpired,
        ', inserted=',@RowsInserted
      ),
      RowsAffected      = @RowsExpired + @RowsInserted,
      DurationSec       = DATEDIFF(SECOND, @StartTime, SYSUTCDATETIME()),
      Status            = 'Success'
    WHERE LogID = @LogID;

  END TRY
  BEGIN CATCH
    DECLARE @ErrMsg NVARCHAR(MAX) = ERROR_MESSAGE();
    -- 8) Update log to Error
    UPDATE DW.ETL_Log
    SET
      ChangeDescription = 'Incremental SCD2 load failed',
      DurationSec       = DATEDIFF(SECOND, @StartTime, SYSUTCDATETIME()),
      Status            = 'Error',
      Message           = @ErrMsg
    WHERE LogID = @LogID;
    THROW;
  END CATCH
END;
GO
