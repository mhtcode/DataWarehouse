CREATE OR ALTER PROCEDURE [DW].[Initial_Person_Dim]
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE
    @StartTime    DATETIME2(3) = SYSUTCDATETIME(),
    @RowsInserted INT,
    @LogID        BIGINT;

  INSERT INTO DW.ETL_Log (
    ProcedureName, TargetTable, ChangeDescription, ActionTime, Status
  ) VALUES (
    'Initial_Person_Dim',
    'DimPerson',
    'Procedure started - awaiting completion',
    @StartTime,
    'Fatal'
  );
  SET @LogID = SCOPE_IDENTITY();

  BEGIN TRY
    TRUNCATE TABLE [DW].[Temp_Person_table];

    INSERT INTO [DW].[Temp_Person_table] (
      PersonID, NationalCode, PassportNumber, Name,
      Gender, DateOfBirth, City, Country,
      Email, Phone, Address, PostalCode
    )
    SELECT
      p.PersonID,
      p.NatCode,
      pas.PassportNumber,
      p.Name,
      p.Gender,
      p.DateOfBirth,
      p.City,
      p.Country,
      p.Email,
      p.Phone,
      p.Address,
      p.PostalCode
    FROM SA.Person AS p
    LEFT JOIN SA.Passenger AS pas
      ON p.PersonID = pas.PersonID;

    INSERT INTO DW.DimPerson (
      PersonID,
      NationalCode,
      PassportNumber,
      Name,
      Gender,
      DateOfBirth,
      City,
      Country,
      Email,
      Phone,
      Address,
      PostalCode,
      EffectiveFrom,
      EffectiveTo,
      PassportNumberIsCurrent
    )
    SELECT
      t.PersonID,
      t.NationalCode,
      t.PassportNumber,
      t.Name,
      t.Gender,
      t.DateOfBirth,
      t.City,
      t.Country,
      t.Email,
      t.Phone,
      t.Address,
      t.PostalCode,
      '1950-01-01 00:00:00',
      NULL,
      1
    FROM [DW].[Temp_Person_table] AS t
    WHERE NOT EXISTS (
      SELECT 1
      FROM DW.DimPerson AS d
      WHERE d.PersonID = t.PersonID
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
      ChangeDescription = 'Initial full load failed',
      RowsAffected      = NULL,
      DurationSec       = DATEDIFF(SECOND, @StartTime, SYSUTCDATETIME()),
      Status            = 'Error',
      Message           = @ErrMsg
    WHERE LogID = @LogID;
    THROW;
  END CATCH
END;
GO
