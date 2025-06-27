CREATE OR ALTER PROCEDURE [SA].[ETL_Payment]
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE
        @StartTime     DATETIME2(3) = SYSUTCDATETIME(),
        @RowsAffected  INT,
        @LogID         BIGINT;

    -- 1) Assume fatal: insert initial log entry
    INSERT INTO [SA].[ETL_Log] (
        ProcedureName,
        SourceTable,
        TargetTable,
        ChangeDescription,
        ActionTime,
        Status
    )
    VALUES (
        'ETL_Payment',
        'Source.Payment',
        'SA.Payment',
        'Procedure started - awaiting completion',
        @StartTime,
        'Fatal'
    );
    SET @LogID = SCOPE_IDENTITY();

    BEGIN TRY
        -- 2) Perform the merge
        MERGE [SA].[Payment] AS TARGET
        USING [Source].[Payment] AS SOURCE
          ON TARGET.PaymentID = SOURCE.PaymentID

        WHEN MATCHED AND EXISTS (
            SELECT
                SOURCE.ReservationID,
                SOURCE.BuyerID,
                SOURCE.Status,
                SOURCE.TicketPrice,
                SOURCE.RealPrice,
                SOURCE.Discount,
                SOURCE.Tax,
                SOURCE.Method,
                SOURCE.PaymentDateTime
            EXCEPT
            SELECT
                TARGET.ReservationID,
                TARGET.BuyerID,
                TARGET.Status,
                TARGET.TicketPrice,
                TARGET.RealPrice,
                TARGET.Discount,
                TARGET.Tax,
                TARGET.Method,
                TARGET.PaymentDateTime
        ) THEN
            UPDATE SET
                TARGET.ReservationID                   = SOURCE.ReservationID,
                TARGET.BuyerID                         = SOURCE.BuyerID,
                TARGET.Status                          = NULLIF(TRIM(SOURCE.Status), ''),
                TARGET.TicketPrice                     = SOURCE.TicketPrice,
                TARGET.RealPrice                       = SOURCE.RealPrice,
                TARGET.Discount                        = SOURCE.Discount,
                TARGET.Tax                             = SOURCE.Tax,
                TARGET.Method                          = NULLIF(TRIM(SOURCE.Method), ''),
                TARGET.PaymentDateTime                 = SOURCE.PaymentDateTime,
                TARGET.StagingLastUpdateTimestampUTC   = GETUTCDATE()

        WHEN NOT MATCHED BY TARGET THEN
            INSERT (
                PaymentID,
                ReservationID,
                BuyerID,
                Status,
                TicketPrice,
                RealPrice,
                Discount,
                Tax,
                Method,
                PaymentDateTime,
                StagingLoadTimestampUTC,
                SourceSystem
            )
            VALUES (
                SOURCE.PaymentID,
                SOURCE.ReservationID,
                SOURCE.BuyerID,
                NULLIF(TRIM(SOURCE.Status), ''),
                SOURCE.TicketPrice,
                SOURCE.RealPrice,
                SOURCE.Discount,
                SOURCE.Tax,
                NULLIF(TRIM(SOURCE.Method), ''),
                SOURCE.PaymentDateTime,
                GETUTCDATE(),
                'OperationalDB'
            );

        SET @RowsAffected = @@ROWCOUNT;

        -- 3) Update log to Success
        UPDATE [SA].[ETL_Log]
        SET
            ChangeDescription = CONCAT('Merge complete: rows affected=', @RowsAffected),
            RowsAffected      = @RowsAffected,
            DurationSec       = DATEDIFF(SECOND, @StartTime, SYSUTCDATETIME()),
            Status            = 'Success'
        WHERE LogID = @LogID;
    END TRY
    BEGIN CATCH
        -- 4) Update log to Error
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
