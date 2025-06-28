CREATE OR ALTER PROCEDURE DW.Initial_FlightDelay_PeriodicSnapshotFact
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE 
        @StartDate    DATE,
        @EndDate      DATE,
        @CurrentDate  DATE;

    -- Determine the date range from the transactional fact
    SELECT
        @StartDate = MIN(CAST(ActualDepartureId AS DATE)),
        @EndDate   = MAX(CAST(ActualDepartureId AS DATE))
    FROM DW.FlightPerformance_TransactionalFact;

    IF @StartDate IS NULL
    BEGIN
        RAISERROR('No data found for initial load.', 16, 1);
        RETURN;
    END

    -- Clean out any existing snapshots
    TRUNCATE TABLE DW.FlightDelay_PeriodicSnapshotFact;

    SET @CurrentDate = @StartDate;

    WHILE @CurrentDate <= @EndDate
    BEGIN
        DECLARE 
            @LogID       BIGINT,
            @StartTime   DATETIME2(3) = SYSUTCDATETIME(),
            @RowCount    INT;

        -- Log start of this day's run
        INSERT INTO DW.ETL_Log
            (ProcedureName, TargetTable, ChangeDescription, ActionTime, Status)
        VALUES
            ('Initial_FlightDelay_PeriodicSnapshotFact',
             'FlightDelay_PeriodicSnapshotFact',
             'Started initial load for date: ' + CONVERT(varchar(10), @CurrentDate, 120),
             @StartTime,
             'Running');
        SET @LogID = SCOPE_IDENTITY();

        BEGIN TRY
            -- STEP A: Load raw daily fact data
            SELECT
                ActualDepartureId,
                DepartureDelayMinutes,
                ArrivalDelayMinutes,
                AirlineId,
                DepartureAirportId,
                ArrivalAirportId
            INTO #Temp_DailyFlightData
            FROM DW.FlightPerformance_TransactionalFact
            WHERE CAST(ActualDepartureId AS DATE) = @CurrentDate;

            IF @@ROWCOUNT = 0
            BEGIN
                -- No data for this date
                UPDATE DW.ETL_Log
                   SET ChangeDescription = 'No records for date: ' 
                                           + CONVERT(varchar(10), @CurrentDate, 120),
                       RowsAffected      = 0,
                       DurationSec       = DATEDIFF(SECOND, @StartTime, SYSUTCDATETIME()),
                       Status            = 'Success'
                 WHERE LogID = @LogID;

                SET @CurrentDate = DATEADD(DAY, 1, @CurrentDate);
                CONTINUE;
            END

            -- STEP B: Enrich SCD2 dimensions & aggregate
            SELECT
                ddt.DateTimeKey            AS SnapshotDateKey,
                da.AirlineKey              AS AirlineKey,
                dap.AirportKey             AS DepartureAirportKey,
                aap.AirportKey             AS ArrivalAirportKey,
                COUNT(*)                   AS TotalFlights,
                SUM(CASE WHEN t.ActualDepartureId IS NULL THEN 1 ELSE 0 END)
                                          AS CancelledFlights,
                SUM(CASE WHEN t.DepartureDelayMinutes > 0 THEN 1 ELSE 0 END)
                                          AS DelayedFlights,
                AVG(t.DepartureDelayMinutes)     AS AvgDepartureDelayMinutes,
                AVG(t.ArrivalDelayMinutes)       AS AvgArrivalDelayMinutes,
                MAX(
                  CASE 
                    WHEN t.DepartureDelayMinutes > t.ArrivalDelayMinutes 
                    THEN t.DepartureDelayMinutes 
                    ELSE t.ArrivalDelayMinutes 
                  END
                )                          AS MaxDelayMinutes
            INTO #Temp_EnrichedDailySnapshot
            FROM #Temp_DailyFlightData AS t
            JOIN DW.DimDateTime AS ddt
              ON CAST(ddt.FullDateTime AS DATE) = @CurrentDate
            JOIN DW.DimAirline AS da
              ON da.BusinessKey = t.AirlineId
             AND @CurrentDate BETWEEN da.EffectiveFrom 
                                  AND ISNULL(da.EffectiveTo, '9999-12-31')
            JOIN DW.DimAirport AS dap
              ON dap.BusinessKey = t.DepartureAirportId
             AND @CurrentDate BETWEEN dap.EffectiveFrom 
                                  AND ISNULL(dap.EffectiveTo, '9999-12-31')
            JOIN DW.DimAirport AS aap
              ON aap.BusinessKey = t.ArrivalAirportId
             AND @CurrentDate BETWEEN aap.EffectiveFrom 
                                  AND ISNULL(aap.EffectiveTo, '9999-12-31')
            GROUP BY ddt.DateTimeKey, da.AirlineKey, dap.AirportKey, aap.AirportKey;

            -- STEP C: Insert into periodic snapshot
            INSERT INTO DW.FlightDelay_PeriodicSnapshotFact (
                SnapshotDateKey,
                AirlineKey,
                DepartureAirportKey,
                ArrivalAirportKey,
                TotalFlights,
                DelayedFlights,
                CancelledFlights,
                AvgDepartureDelayMinutes,
                AvgArrivalDelayMinutes,
                MaxDelayMinutes,
                DelayRate,
                OnTimePercentage
            )
            SELECT
                SnapshotDateKey,
                AirlineKey,
                DepartureAirportKey,
                ArrivalAirportKey,
                TotalFlights,
                DelayedFlights,
                CancelledFlights,
                AvgDepartureDelayMinutes,
                AvgArrivalDelayMinutes,
                MaxDelayMinutes,
                CASE WHEN TotalFlights = 0 THEN NULL 
                     ELSE CAST(DelayedFlights AS FLOAT) / TotalFlights END,
                CASE WHEN TotalFlights = 0 THEN NULL 
                     ELSE 1 - CAST(DelayedFlights AS FLOAT) / TotalFlights END
            FROM #Temp_EnrichedDailySnapshot;

            SET @RowCount = @@ROWCOUNT;

            -- STEP D: Clean up & log success
            DROP TABLE #Temp_DailyFlightData;
            DROP TABLE #Temp_EnrichedDailySnapshot;

            UPDATE DW.ETL_Log
               SET ChangeDescription = 'Initial load complete for date: ' 
                                       + CONVERT(varchar(10), @CurrentDate, 120),
                   RowsAffected      = @RowCount,
                   DurationSec       = DATEDIFF(SECOND, @StartTime, SYSUTCDATETIME()),
                   Status            = 'Success'
             WHERE LogID = @LogID;
        END TRY
        BEGIN CATCH
            DECLARE @ErrMsg NVARCHAR(MAX) = ERROR_MESSAGE();
            UPDATE DW.ETL_Log
               SET ChangeDescription = 'Initial load failed for date: ' 
                                       + CONVERT(varchar(10), @CurrentDate, 120),
                   DurationSec       = DATEDIFF(SECOND, @StartTime, SYSUTCDATETIME()),
                   Status            = 'Error',
                   Message           = @ErrMsg
             WHERE LogID = @LogID;
            THROW;
        END CATCH

        SET @CurrentDate = DATEADD(DAY, 1, @CurrentDate);
    END
END;
GO