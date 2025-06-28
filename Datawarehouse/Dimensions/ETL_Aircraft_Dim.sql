CREATE OR ALTER PROCEDURE [DW].[ETL_Aircraft_Dim]
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE
    @StartTime    DATETIME2(3) = SYSUTCDATETIME(),
    @LastRunTime  DATETIME2(3),
    @RowsUpdated  INT,
    @RowsInserted INT,
    @LogID        BIGINT;

  -- 1) Assume fatal: insert initial log entry
  INSERT INTO DW.ETL_Log (
    ProcedureName,
    TargetTable,
    ChangeDescription,
    ActionTime,
    Status
  ) VALUES (
    'ETL_Aircraft_Dim',
    'DimAircraft',
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
    WHERE ProcedureName = 'ETL_Aircraft_Dim'
      AND Status = 'Success';

    -- 3) Truncate staging
    TRUNCATE TABLE [DW].[Temp_Aircraft_table];

    -- 4) Populate staging with changed/new aircrafts
    INSERT INTO [DW].[Temp_Aircraft_table] (
      AircraftID,
      Model,
      Type,
      ManufacturerDate,
      Capacity,
      Price
    )
    SELECT
      a.AircraftID,
      a.Model,
      a.Type,
      a.ManufacturerDate,
      a.Capacity,
      a.Price
    FROM SA.Aircraft AS a
    WHERE a.StagingLastUpdateTimestampUTC > @LastRunTime;

    -- 5) Update existing aircrafts in dimension
    UPDATE d
    SET
      d.Model            = t.Model,
      d.Type             = t.Type,
      d.ManufacturerDate = t.ManufacturerDate,
      d.Capacity         = t.Capacity,
      d.Price            = t.Price
    FROM DW.DimAircraft AS d
    JOIN DW.Temp_Aircraft_table AS t
      ON d.AircraftID = t.AircraftID;
    SET @RowsUpdated = @@ROWCOUNT;

    -- 6) Insert new aircrafts into dimension
    INSERT INTO DW.DimAircraft (
      AircraftID,
      Model,
      Type,
      ManufacturerDate,
      Capacity,
      Price
    )
    SELECT
      t.AircraftID,
      t.Model,
      t.Type,
      t.ManufacturerDate,
      t.Capacity,
      t.Price
    FROM DW.Temp_Aircraft_table AS t
    WHERE NOT EXISTS (
      SELECT 1
      FROM DW.DimAircraft AS d
      WHERE d.AircraftID = t.AircraftID
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
END
GO
