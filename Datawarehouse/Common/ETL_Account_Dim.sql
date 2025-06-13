CREATE OR ALTER PROCEDURE [DW].[ETL_Account_Dim]
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
    'ETL_Account_Dim',
    'DimAccount',
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
    WHERE ProcedureName = 'ETL_Account_Dim'
      AND Status = 'Success';

    -- 3) Truncate staging
    TRUNCATE TABLE [DW].[Temp_Account_table];

    -- 4) Populate staging with changed/new accounts
    INSERT INTO [DW].[Temp_Account_table] (
      AccountID,
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
    WHERE a.StagingLastUpdateTimestampUTC > @LastRunTime;

    -- 5) Update existing accounts in dimension
    UPDATE d
    SET
      d.AccountNumber = t.AccountNumber,
      d.AccountType   = t.AccountType,
      d.CreatedDate   = t.CreatedDate,
      d.IsActive      = t.IsActive
    FROM DW.DimAccount AS d
    JOIN DW.Temp_Account_table AS t
      ON d.AccountKey = t.AccountID;
    SET @RowsUpdated = @@ROWCOUNT;

    -- 6) Insert new accounts into dimension
    INSERT INTO DW.DimAccount (
      AccountKey,
      AccountNumber,
      AccountType,
      CreatedDate,
      IsActive
    )
    SELECT
      t.AccountID,
      t.AccountNumber,
      t.AccountType,
      t.CreatedDate,
      t.IsActive
    FROM DW.Temp_Account_table AS t
    WHERE NOT EXISTS (
      SELECT 1 FROM DW.DimAccount AS d
      WHERE d.AccountKey = t.AccountID
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
END;
GO