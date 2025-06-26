CREATE OR ALTER PROCEDURE [DW].[Initial_LoyaltyTransactionType_Dim]
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE
    @StartTime    DATETIME2(3) = SYSUTCDATETIME(),
    @RowsInserted INT,
    @LogID        BIGINT;

  -- 1. Insert fatal log entry
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
    -- 2. Truncate dim for initial full load
    TRUNCATE TABLE DW.DimLoyaltyTransactionType;

    -- 3. Load all transaction types from SA
    INSERT INTO DW.DimLoyaltyTransactionType (
      LoyaltyTransactionTypeID,
      TypeName
    )
    SELECT
      LoyaltyTransactionTypeID,
      TypeName
    FROM SA.LoyaltyTransactionType;

    SET @RowsInserted = @@ROWCOUNT;

    -- 4. Mark log as success
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
    -- 5. Mark log as error
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
