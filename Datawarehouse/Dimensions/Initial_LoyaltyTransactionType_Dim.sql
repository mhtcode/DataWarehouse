CREATE OR ALTER PROCEDURE [DW].[Initial_LoyaltyTransactionType_Dim]
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
    'Initial_LoyaltyTransactionType_Dim',
    'DimLoyaltyTransactionType',
    'Procedure started - awaiting completion',
    @StartTime,
    'Fatal'
  );
  SET @LogID = SCOPE_IDENTITY();

  BEGIN TRY
    -- 2) Insert all distinct transaction types with surrogate keys
    INSERT INTO DW.DimLoyaltyTransactionType (
      TransactionTypeKey,
      TransactionTypeName
    )
    SELECT
      ROW_NUMBER() OVER (ORDER BY t.TransactionType) AS TransactionTypeKey,
      t.TransactionType
    FROM (
      SELECT DISTINCT TransactionType
      FROM SA.PointsTransaction
    ) AS t;
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
      ChangeDescription = 'Initial full load failed',
      DurationSec       = DATEDIFF(SECOND, @StartTime, SYSUTCDATETIME()),
      Status            = 'Error',
      Message           = @ErrMsg
    WHERE LogID = @LogID;
    THROW;
  END CATCH
END;
GO
