CREATE OR ALTER PROCEDURE [DW].[Initial_Account_Dim]
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
    'Initial_Account_Dim',
    'DimAccount',
    'Procedure started - awaiting completion',
    @StartTime,
    'Fatal'
  );
  SET @LogID = SCOPE_IDENTITY();

  BEGIN TRY
    -- 2) Insert all new accounts into dimension
    INSERT INTO DW.DimAccount (
      AccountKey,
      AccountNumber,
      AccountType,
      CreatedDate,
      IsActive
    )
    SELECT
      a.AccountID,
      a.AccountNumber,
      a.AccountType,
      a.CreatedDate,
      a.IsActive
    FROM SA.Account AS a
    WHERE NOT EXISTS (
      SELECT 1 FROM DW.DimAccount AS d
      WHERE d.AccountKey = a.AccountID
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
