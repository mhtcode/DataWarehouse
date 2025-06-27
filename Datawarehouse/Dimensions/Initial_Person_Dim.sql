CREATE OR ALTER PROCEDURE [DW].[Initial_Person_Dim]
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE
    @StartTime    DATETIME2(3) = SYSUTCDATETIME(),
    @RowsInserted INT,
    @LogID        BIGINT;

  -- 1) Insert initial "Fatal" log entry
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
    -- 2) Clean staging
    TRUNCATE TABLE [DW].[Temp_Person_table];

    -- 3) Populate staging with all source rows
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

    -- 4) Insert new persons into dimension
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
      @StartTime,
      NULL,
      1
    FROM [DW].[Temp_Person_table] AS t
    WHERE NOT EXISTS (
      SELECT 1
      FROM DW.DimPerson AS d
      WHERE d.PersonID = t.PersonID
    );
    SET @RowsInserted = @@ROWCOUNT;

    -- 5) Update log entry to Success
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
    -- 6) Update log entry to Error
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