CREATE OR ALTER PROCEDURE [SA].[ETL_FlightOperation]
AS
BEGIN
    MERGE [SA].[FlightOperation] AS TARGET
    USING [Source].[FlightOperation] AS SOURCE
    ON (TARGET.FlightOperationID = SOURCE.FlightOperationID)

    -- Action for existing records that have changed
    WHEN MATCHED AND EXISTS (
        -- This clause correctly compares all relevant columns for any changes.
        SELECT SOURCE.FlightDetailID, SOURCE.ActualDepartureDateTime, SOURCE.ActualArrivalDateTime, SOURCE.DelayMinutes, SOURCE.CancelFlag, SOURCE.LoadFactor, SOURCE.DelaySeverityScore
        EXCEPT
        SELECT TARGET.FlightDetailID, TARGET.ActualDepartureDateTime, TARGET.ActualArrivalDateTime, TARGET.DelayMinutes, TARGET.CancelFlag, TARGET.LoadFactor, TARGET.DelaySeverityScore
    ) THEN
        UPDATE SET
            TARGET.FlightDetailID            = SOURCE.FlightDetailID,
            TARGET.ActualDepartureDateTime   = SOURCE.ActualDepartureDateTime,
            TARGET.ActualArrivalDateTime     = SOURCE.ActualArrivalDateTime,
            TARGET.DelayMinutes              = SOURCE.DelayMinutes,
            TARGET.CancelFlag                = SOURCE.CancelFlag,
            TARGET.LoadFactor                = SOURCE.LoadFactor,
            TARGET.DelaySeverityScore        = SOURCE.DelaySeverityScore,
            TARGET.StagingLastUpdateTimestampUTC = GETUTCDATE()

    -- Action for new records
    WHEN NOT MATCHED BY TARGET THEN
        INSERT (
            FlightOperationID,
            FlightDetailID,
            ActualDepartureDateTime,
            ActualArrivalDateTime,
            DelayMinutes,
            CancelFlag,
            LoadFactor,
            DelaySeverityScore,
            StagingLoadTimestampUTC,
            SourceSystem
        )
        VALUES (
            SOURCE.FlightOperationID,
            SOURCE.FlightDetailID,
            SOURCE.ActualDepartureDateTime,
            SOURCE.ActualArrivalDateTime,
            SOURCE.DelayMinutes,
            SOURCE.CancelFlag,
            SOURCE.LoadFactor,
            SOURCE.DelaySeverityScore,
            GETUTCDATE(),
            'OperationalDB'
        ); -- Mandatory Semicolon

END
