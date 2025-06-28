CREATE OR ALTER PROCEDURE DW.Load_FlightDelay_PeriodicSnapshotFact
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE 
        @LastDate     DATE,
        @MaxDate      DATE,
        @CurrentDate  DATE;

    -- Get last snapshot date
    SELECT @LastDate = MAX(SnapshotDateKey)
    FROM DW.FlightDelay_PeriodicSnapshotFact;

    -- Get latest available fact date
    SELECT @MaxDate = MAX(CAST(ActualDepartureId AS DATE))
    FROM DW.FlightPerformance_TransactionalFact;

    IF @LastDate IS NULL
    BEGIN
        RAISERROR('Snapshot table empty – run initial load first.', 16, 1);
        RETURN;
    END

    IF @LastDate >= @MaxDate
        RETURN;  -- already up to date

    SET @CurrentDate = DATEADD(DAY, 1, @LastDate);

    WHILE @CurrentDate <= @MaxDate
    BEGIN
        DECLARE 
            @LogID       BIGINT,
            @StartTime   DATETIME2(3) = SYSUTCDATETIME(),
            @RowCount    INT;

        -- Log start of incremental run
        INSERT INTO DW.ETL_Log
            (ProcedureName, TargetTable, ChangeDescription, ActionTime, Status)
        VALUES
            ('Load_FlightDelay_PeriodicSnapshotFact',
             'FlightDelay_PeriodicSnapshotFact',
             'Started incremental load for date: ' + CONVERT(varchar(10), @CurrentDate, 120),
             @StartTime,
             'Running');
        SET @LogID = SCOPE_IDENTITY();

        BEGIN TRY
            -- STEP A–C: same as initial but only for @CurrentDate
            SELECT
                fp.ActualDepartureId,
                fp.DepartureDelayMinutes,
                fp.ArrivalDelayMinutes,
                fp.AirlineId,
                fp.DepartureAirportId,
                fp.ArrivalAirportId
            INTO #Temp_DailyFlightData
            FROM DW.FlightPerformance_TransactionalFact fp
            WHERE CAST(fp.ActualDepartureId AS DATE) = @CurrentDate;

            IF @@ROWCOUNT = 0
            BEGIN
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

            DROP TABLE #Temp_DailyFlightData;
            DROP TABLE #Temp_EnrichedDailySnapshot;

            UPDATE DW.ETL_Log
               SET ChangeDescription = 'Incremental load complete for date: ' 
                                       + CONVERT(varchar(10), @CurrentDate, 120),
                   RowsAffected      = @RowCount,
                   DurationSec       = DATEDIFF(SECOND, @StartTime, SYSUTCDATETIME()),
                   Status            = 'Success'
             WHERE LogID = @LogID;
        END TRY
        BEGIN CATCH
            DECLARE @ErrMsg NVARCHAR(MAX) = ERROR_MESSAGE();
            UPDATE DW.ETL_Log
               SET ChangeDescription = 'Incremental load failed for date: ' 
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