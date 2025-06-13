CREATE OR ALTER PROCEDURE [DW].[Initial_Person_Dim]
AS
BEGIN
  SET NOCOUNT ON;
  
  DECLARE
    @StartTime    DATETIME2(3) = SYSUTCDATETIME(),
    @RowsInserted INT;

  BEGIN TRY
    -- clean staging
    TRUNCATE TABLE [DW].[Temp_Person_table];

    -- populate staging with all source rows
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

    -- insert new keys into dimension
    INSERT INTO DW.DimPerson (
      PersonKey, NationalCode, PassportNumber, Name,
      Gender, DateOfBirth, City, Country,
      Email, Phone, Address, PostalCode,
      EffectiveFrom, EffectiveTo, PassportNumberIsCurrent
    )
    SELECT
      t.PersonID, t.NationalCode, t.PassportNumber, t.Name,
      t.Gender, t.DateOfBirth, t.City, t.Country,
      t.Email, t.Phone, t.Address, t.PostalCode,
      @StartTime, NULL, 1
    FROM DW.Temp_Person_table AS t
    WHERE NOT EXISTS (
      SELECT 1 FROM DW.DimPerson AS d WHERE d.PersonKey = t.PersonID
    );
    
    SET @RowsInserted = @@ROWCOUNT;
    
    -- log success
    INSERT INTO DW.ETL_Log (
      ProcedureName, TargetTable, ChangeDescription,
      RowsAffected, ActionTime, DurationSec, Status
    )
    VALUES (
      'Initial_Person_Dim',
      'DimPerson',
      'Initial full load using Temp_Person_table',
      @RowsInserted,
      @StartTime,
      DATEDIFF(SECOND, @StartTime, SYSUTCDATETIME()),
      'Success'
    );
  END TRY
  BEGIN CATCH
    DECLARE @ErrorMessage NVARCHAR(MAX) = ERROR_MESSAGE();
    -- log error
    INSERT INTO DW.ETL_Log (
      ProcedureName, TargetTable, ChangeDescription,
      RowsAffected, ActionTime, DurationSec, Status, Message
    )
    VALUES (
      'Initial_Person_Dim',
      'DimPerson',
      'Initial full load using Temp_Person_table failed',
      NULL,
      @StartTime,
      DATEDIFF(SECOND, @StartTime, SYSUTCDATETIME()),
      'Error',
      @ErrorMessage
    );
    THROW;
  END CATCH
END
GO