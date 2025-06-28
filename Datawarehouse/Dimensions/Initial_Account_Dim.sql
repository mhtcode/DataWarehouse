CREATE OR ALTER PROCEDURE [DW].[Initial_Account_Dim]
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE
    @StartTime     DATETIME2(3) = SYSUTCDATETIME(),
    @RowsInserted  INT,
    @LogID         BIGINT;

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
    TRUNCATE TABLE DW.DimAccount;

    INSERT INTO DW.DimAccount (
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
      JOIN SA.LoyaltyTier t ON a.LoyaltyTierID = t.LoyaltyTierID;

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
