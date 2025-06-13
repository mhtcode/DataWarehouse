CREATE OR ALTER PROCEDURE [DW].[Initial_Aircraft_Dim]
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
    'Initial_Aircraft_Dim',
    'DimAircraft',
    'Procedure started - awaiting completion',
    @StartTime,
    'Fatal'
  );
  SET @LogID = SCOPE_IDENTITY();

  BEGIN TRY
    -- 2) Truncate staging
    TRUNCATE TABLE [DW].[Temp_Aircraft_table];

    -- 3) Populate staging with all source rows
    INSERT INTO [DW].[Temp_Aircraft_table] (
      AircraftID, Model, Type, ManufacturerDate, Capacity, Price
    )
    SELECT
      a.AircraftID,
      a.Model,
      a.Type,
      a.ManufacturerDate,
      a.Capacity,
      a.Price
    FROM SA.Aircraft AS a;

    -- 4) Insert new aircrafts into dimension
    INSERT INTO DW.DimAircraft (
      AircraftKey, Model, Type, ManufacturerDate, Capacity, Price
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
      SELECT 1 FROM DW.DimAircraft AS d
      WHERE d.AircraftKey = t.AircraftID
    );
    SET @RowsInserted = @@ROWCOUNT;

    -- 5) Update log to Success
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
    -- 6) Update log to Error
    UPDATE DW.ETL_Log
    SET
      ChangeDescription = 'Initial load failed',
      DurationSec       = DATEDIFF(SECOND, @StartTime, SYSUTCDATETIME()),
      Status            = 'Error',
      Message           = @ErrMsg
    WHERE LogID = @LogID;
    THROW;
  END CATCH
END
GO