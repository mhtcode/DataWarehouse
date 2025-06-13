CREATE OR ALTER PROCEDURE [DW].[ETL_Payment_Dim]
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
    'ETL_Payment_Dim',
    'DimPayment',
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
    WHERE ProcedureName = 'ETL_Payment_Dim'
      AND Status = 'Success';

    -- 3) Truncate staging
    TRUNCATE TABLE [DW].[Temp_Payment_table];

    -- 4) Populate staging with changed/new payments
    INSERT INTO DW.Temp_Payment_table (
      PaymentID, PaymentMethod, PaymentStatus, PaymentTimestamp
    )
    SELECT
      p.PaymentID,
      p.Method         AS PaymentMethod,
      p.Status         AS PaymentStatus,
      p.PaymentDateTime AS PaymentTimestamp
    FROM SA.Payment AS p
    WHERE p.StagingLastUpdateTimestampUTC > @LastRunTime;

    -- 5) Update existing payments in dimension
    UPDATE d
    SET
      d.PaymentMethod    = t.PaymentMethod,
      d.PaymentStatus    = t.PaymentStatus,
      d.PaymentTimestamp = t.PaymentTimestamp
    FROM DW.DimPayment AS d
    JOIN DW.Temp_Payment_table AS t
      ON d.PaymentKey = t.PaymentID;
    SET @RowsUpdated = @@ROWCOUNT;

    -- 6) Insert new payments into dimension
    INSERT INTO DW.DimPayment (
      PaymentKey, PaymentMethod, PaymentStatus, PaymentTimestamp
    )
    SELECT
      t.PaymentID,
      t.PaymentMethod,
      t.PaymentStatus,
      t.PaymentTimestamp
    FROM DW.Temp_Payment_table AS t
    WHERE NOT EXISTS (
      SELECT 1 FROM DW.DimPayment AS d
      WHERE d.PaymentKey = t.PaymentID
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