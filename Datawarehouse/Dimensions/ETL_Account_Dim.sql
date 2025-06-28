CREATE OR ALTER PROCEDURE [DW].[ETL_Account_Dim]
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE
    @StartTime     DATETIME2(3) = SYSUTCDATETIME(),
    @LastRunTime   DATETIME2(3),
    @RowsUpdated   INT = 0,
    @RowsInserted  INT = 0,
    @LogID         BIGINT;

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
    SELECT
      @LastRunTime = COALESCE(MAX(ActionTime), '1900-01-01')
    FROM DW.ETL_Log
    WHERE ProcedureName = 'ETL_Account_Dim'
      AND Status = 'Success';

    TRUNCATE TABLE DW.Temp_Account_table;

    INSERT INTO DW.Temp_Account_table (
      AccountID,
      PassengerName,
      RegistrationDate,
      LoyaltyTierName
    )
    SELECT
      a.AccountID,
      p.Name AS PassengerName,
      a.RegistrationDate,
      t.Name AS LoyaltyTierName
    FROM SA.Account AS a
      JOIN SA.Passenger ps ON a.PassengerID = ps.PassengerID
      JOIN SA.Person p ON ps.PersonID = p.PersonID
      JOIN SA.LoyaltyTier t ON a.LoyaltyTierID = t.LoyaltyTierID
    WHERE a.StagingLastUpdateTimestampUTC > @LastRunTime;

    UPDATE d
    SET
      d.PassengerName    = t.PassengerName,
      d.RegistrationDate = t.RegistrationDate,
      d.LoyaltyTierName  = t.LoyaltyTierName
    FROM DW.DimAccount AS d
    JOIN DW.Temp_Account_table AS t
      ON d.AccountID = t.AccountID
    WHERE
      (
        ISNULL(d.PassengerName, '')    <> ISNULL(t.PassengerName, '')
        OR ISNULL(d.RegistrationDate, '1900-01-01') <> ISNULL(t.RegistrationDate, '1900-01-01')
        OR ISNULL(d.LoyaltyTierName, '')<> ISNULL(t.LoyaltyTierName, '')
      );
    SET @RowsUpdated = @@ROWCOUNT;

    INSERT INTO DW.DimAccount (
      AccountID,
      PassengerName,
      RegistrationDate,
      LoyaltyTierName
    )
    SELECT
      t.AccountID,
      t.PassengerName,
      t.RegistrationDate,
      t.LoyaltyTierName
    FROM DW.Temp_Account_table AS t
    WHERE NOT EXISTS (
      SELECT 1 FROM DW.DimAccount AS d
      WHERE d.AccountID = t.AccountID
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
    UPDATE DW.ETL_Log
    SET
      ChangeDescription = 'Incremental load failed',
      DurationSec       = DATEDIFF(SECOND, @StartTime, SYSUTCDATETIME()),
      Status            = 'Error',
      Message           = ERROR_MESSAGE()
    WHERE LogID = @LogID;
    THROW;
  END CATCH
END
GO
