CREATE OR ALTER PROCEDURE [SA].[ETL_Account]
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE
        @StartTime     DATETIME2(3) = SYSUTCDATETIME(),
        @RowsAffected  INT,
        @LogID         BIGINT;

    INSERT INTO [SA].[ETL_Log] (
        ProcedureName,
        SourceTable,
        TargetTable,
        ChangeDescription,
        ActionTime,
        Status
    )
    VALUES (
        'ETL_Account',
        'Source.Account',
        'SA.Account',
        'Procedure started - awaiting completion',
        @StartTime,
        'Fatal'
    );
    SET @LogID = SCOPE_IDENTITY();

    BEGIN TRY
        MERGE [SA].[Account] AS TARGET
        USING [Source].[Account] AS SOURCE
          ON TARGET.AccountID = SOURCE.AccountID

        WHEN MATCHED AND EXISTS (
            SELECT
                SOURCE.PassengerID,
                SOURCE.RegistrationDate,
                SOURCE.LoyaltyTierID
            EXCEPT
            SELECT
                TARGET.PassengerID,
                TARGET.RegistrationDate,
                TARGET.LoyaltyTierID
        ) THEN
            UPDATE SET
                TARGET.PassengerID                   = SOURCE.PassengerID,
                TARGET.RegistrationDate              = SOURCE.RegistrationDate,
                TARGET.LoyaltyTierID                 = SOURCE.LoyaltyTierID,
                TARGET.StagingLastUpdateTimestampUTC = GETUTCDATE()

        WHEN NOT MATCHED BY TARGET THEN
            INSERT (
                AccountID,
                PassengerID,
                RegistrationDate,
                LoyaltyTierID,
                StagingLoadTimestampUTC,
                SourceSystem
            )
            VALUES (
                SOURCE.AccountID,
                SOURCE.PassengerID,
                SOURCE.RegistrationDate,
                SOURCE.LoyaltyTierID,
                GETUTCDATE(),
                'OperationalDB'
            );

        SET @RowsAffected = @@ROWCOUNT;

        UPDATE [SA].[ETL_Log]
        SET
            ChangeDescription = CONCAT('Merge complete: rows affected=', @RowsAffected),
            RowsAffected      = @RowsAffected,
            DurationSec       = DATEDIFF(SECOND, @StartTime, SYSUTCDATETIME()),
            Status            = 'Success'
        WHERE LogID = @LogID;
    END TRY
    BEGIN CATCH
        UPDATE [SA].[ETL_Log]
        SET
            ChangeDescription = 'Merge failed',
            DurationSec       = DATEDIFF(SECOND, @StartTime, SYSUTCDATETIME()),
            Status            = 'Error',
            Message           = ERROR_MESSAGE()
        WHERE LogID = @LogID;
        THROW;
    END CATCH
END;
GO
