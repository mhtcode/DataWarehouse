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
    SELECT
      @LastRunTime = COALESCE(
        MAX(ActionTime),
        '1900-01-01'
      )
    FROM DW.ETL_Log
    WHERE ProcedureName = 'ETL_Aircraft_Dim'
      AND Status = 'Success';

    TRUNCATE TABLE [DW].[Temp_Aircraft_table];

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
