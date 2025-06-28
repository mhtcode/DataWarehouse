CREATE OR ALTER PROCEDURE [DW].[Initial_Aircraft_Dim]
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE
    @StartTime    DATETIME2(3) = SYSUTCDATETIME(),
    @RowsInserted INT,
    @LogID        BIGINT;

  INSERT INTO DW.ETL_Log (
    ProcedureName,
    TargetTable,
    ChangeDescription,
    ActionTime,
    Status
  ) VALUES (
    'Initial_Aircraft_Dim',
    'DimAircraft',
    'Procedure started - awaiting completion',
    @StartTime,
    'Fatal'
  );
  SET @LogID = SCOPE_IDENTITY();

  BEGIN TRY
    INSERT INTO DW.DimAircraft (
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
    WHERE NOT EXISTS (
      SELECT 1
      FROM DW.DimAircraft AS d
      WHERE d.AircraftID = a.AircraftID
    );
    SET @RowsInserted = @@ROWCOUNT;

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