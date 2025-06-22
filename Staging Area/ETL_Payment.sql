CREATE OR ALTER PROCEDURE [SA].[ETL_Payment]
AS
BEGIN
    MERGE [SA].[Payment] AS TARGET
    USING [Source].[Payment] AS SOURCE
    ON (TARGET.PaymentID = SOURCE.PaymentID)

    -- Action for existing records that have changed
    WHEN MATCHED AND EXISTS (
        -- This clause correctly compares all relevant columns for any changes.
        SELECT SOURCE.ReservationID, SOURCE.Status, SOURCE.TicketPrice, SOURCE.RealPrice, SOURCE.Discount, SOURCE.Tax, SOURCE.Method, SOURCE.PaymentDateTime
        EXCEPT
        SELECT TARGET.ReservationID, TARGET.Status, TARGET.TicketPrice, TARGET.RealPrice, TARGET.Discount, TARGET.Tax, TARGET.Method, TARGET.PaymentDateTime
    ) THEN
        UPDATE SET
            TARGET.ReservationID = SOURCE.ReservationID,
            TARGET.Status = NULLIF(TRIM(SOURCE.Status), ''),
            TARGET.TicketPrice = SOURCE.TicketPrice,
            TARGET.RealPrice = SOURCE.RealPrice,
            TARGET.Discount = SOURCE.Discount,
            TARGET.Tax = SOURCE.Tax,
            TARGET.Method = NULLIF(TRIM(SOURCE.Method), ''),
            TARGET.PaymentDateTime = SOURCE.PaymentDateTime,
            TARGET.StagingLastUpdateTimestampUTC = GETUTCDATE()

    -- Action for new records
    WHEN NOT MATCHED BY TARGET THEN
        INSERT (
            PaymentID,
            ReservationID,
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
            NULLIF(TRIM(SOURCE.Status), ''),
            SOURCE.TicketPrice,
            SOURCE.RealPrice,
            SOURCE.Discount,
            SOURCE.Tax,
            NULLIF(TRIM(SOURCE.Method), ''),
            SOURCE.PaymentDateTime,
            GETUTCDATE(),
            'OperationalDB'
        ); -- Mandatory Semicolon

END