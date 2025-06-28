CREATE OR ALTER PROCEDURE [DW].[LoadFactLoyaltyPointTransaction]
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @StartDate date;
    DECLARE @EndDate date;

    -- 1. Determine the max date already in the fact table (TransactionDateKey = datetime)
    SELECT 
        @StartDate = MAX(CAST(TransactionDateKey AS DATE))
    FROM 
        [DW].[FactLoyaltyPointTransaction_Transactional];

    -- 2. Determine the max date available in the staging (TransactionDate = datetime)
    SELECT 
        @EndDate = MAX(CAST(TransactionDate AS DATE))
    FROM 
        [SA].[PointsTransaction];

    IF @EndDate IS NULL
    BEGIN
        RAISERROR('No source PointsTransaction data found. Exiting procedure.', 0, 1) WITH NOWAIT;
        RETURN;
    END

    IF @StartDate IS NULL
        SET @StartDate = @EndDate; -- Optional: Start with latest, or SET to earliest date in PointsTransaction for full load

    IF @StartDate >= @EndDate
    BEGIN
        RAISERROR('FactLoyaltyPointTransaction_Transactional table is up to date!', 0, 1) WITH NOWAIT;
        RETURN;
    END

    DECLARE @CurrentDate date = DATEADD(day, 1, @StartDate); -- Always move forward by one day

    WHILE @CurrentDate <= @EndDate
    BEGIN
        DECLARE @LogID BIGINT;
        DECLARE @StartTime DATETIME2(3) = SYSUTCDATETIME();
        DECLARE @RowCount INT;

        INSERT INTO DW.ETL_Log (ProcedureName, TargetTable, ChangeDescription, ActionTime, Status) 
        VALUES (
            'LoadFactLoyaltyPointTransaction', 
            'FactLoyaltyPointTransaction_Transactional', 
            'Procedure started for date: ' + CONVERT(varchar, @CurrentDate, 101), 
            @StartTime, 'Running'
        );
        
        SET @LogID = SCOPE_IDENTITY();

        BEGIN TRY			
            -- STEP A: Stage the daily loyalty transactions for the current date.
            TRUNCATE TABLE [DW].[Temp_DailyLoyaltyTransactions]; -- Ensure table is empty

            INSERT INTO [DW].[Temp_DailyLoyaltyTransactions]
            (
                PointsTransactionID, AccountID, TransactionDate, LoyaltyTransactionTypeID, 
                PointsChange, BalanceAfterTransaction, USDValue, ConversionRate, 
                PointConversionRateID, ServiceOfferingID, FlightDetailID
            )
            SELECT 
                PointsTransactionID, AccountID, TransactionDate, LoyaltyTransactionTypeID, 
                PointsChange, BalanceAfterTransaction, USDValue, ConversionRate, 
                PointConversionRateID, ServiceOfferingID, FlightDetailID
            FROM [SA].[PointsTransaction]
            WHERE CAST(TransactionDate AS DATE) = @CurrentDate;

            IF @@ROWCOUNT = 0 
            BEGIN
                UPDATE DW.ETL_Log 
                SET ChangeDescription = 'No loyalty transactions found for date: ' + CONVERT(varchar, @CurrentDate, 101), 
                    RowsAffected = 0, 
                    DurationSec = DATEDIFF(SECOND, @StartTime, SYSUTCDATETIME()), 
                    Status = 'Success' 
                WHERE LogID = @LogID;
                SET @CurrentDate = DATEADD(day, 1, @CurrentDate);
                CONTINUE;
            END

            -- STEP B: Enrich the data by joining to dimensions and resolving SCD Type 2 keys.
            TRUNCATE TABLE [DW].[Temp_EnrichedLoyaltyData]; -- Ensure table is empty

            INSERT INTO [DW].[Temp_EnrichedLoyaltyData] (
                TransactionDateKey, PersonKey, AccountKey, LoyaltyTierKey, TransactionTypeKey, 
                ConversionRateKey, FlightKey, ServiceOfferingKey, PointsChange, USDValue, 
                ConversionRateSnapshot, BalanceAfterTransaction
            )
            SELECT
                -- Dimension Keys
                pt.TransactionDate,    -- TransactionDateKey (datetime)
                ISNULL(dp.PersonKey, -1),
                pt.AccountID,
                ISNULL(dlt.LoyaltyTierKey, -1),
                pt.LoyaltyTransactionTypeID,
                ISNULL(dcr.ConversionRateKey, -1),
                pt.FlightDetailID,
                ISNULL(dso.ServiceOfferingID, -1),
                -- Measures
                pt.PointsChange,
                pt.USDValue,
                ISNULL(dcr.Rate, pt.ConversionRate),  -- fallback to staging value if no match
                pt.BalanceAfterTransaction
            FROM [DW].[Temp_DailyLoyaltyTransactions] pt
            INNER JOIN [SA].[Account] acc ON pt.AccountID = acc.AccountID
            INNER JOIN [SA].[Passenger] pass ON acc.PassengerID = pass.PassengerID
            -- SCD Type 2 Join for Person
            LEFT JOIN [DW].[DimPerson] dp ON pass.PersonID = dp.PersonID
                AND pt.TransactionDate >= dp.EffectiveFrom 
                AND pt.TransactionDate < ISNULL(dp.EffectiveTo, '9999-12-31')
            -- SCD Type 2 Join to find which tier the account was in
            LEFT JOIN [SA].[AccountTierHistory] ath ON pt.AccountID = ath.AccountID
                AND pt.TransactionDate >= ath.EffectiveFrom
                AND pt.TransactionDate < ISNULL(ath.EffectiveTo, '9999-12-31')
            -- SCD Type 2 Join to find the correct version of that tier
            LEFT JOIN [DW].[DimLoyaltyTier] dlt ON ath.LoyaltyTierID = dlt.LoyaltyTierID
                AND pt.TransactionDate >= dlt.EffectiveFrom
                AND pt.TransactionDate < ISNULL(dlt.EffectiveTo, '9999-12-31')
            -- SCD Type 2 Join for Point Conversion Rate
            LEFT JOIN [DW].[DimPointConversionRate] dcr ON pt.PointConversionRateID = dcr.PointConversionRateID
                AND pt.TransactionDate >= dcr.EffectiveFrom
                AND pt.TransactionDate < ISNULL(dcr.EffectiveTo, '9999-12-31')
            -- Join for Service Offering (not SCD)
            LEFT JOIN [DW].[DimServiceOffering] dso ON pt.ServiceOfferingID = dso.ServiceOfferingID;

            -- STEP C: Final Insert into the fact table
            INSERT INTO [DW].[FactLoyaltyPointTransaction_Transactional] (
                TransactionDateKey, PersonKey, AccountKey, LoyaltyTierKey, TransactionTypeKey,
                ConversionRateKey, FlightKey, ServiceOfferingKey, PointsEarned, PointsRedeemed,
                USDValue, ConversionRateSnapshot, BalanceAfterTransaction
            )
            SELECT
                ed.TransactionDateKey, ed.PersonKey, ed.AccountKey, ed.LoyaltyTierKey, ed.TransactionTypeKey,
                ed.ConversionRateKey, ed.FlightKey, ed.ServiceOfferingKey,
                CASE WHEN ed.PointsChange > 0 THEN ed.PointsChange ELSE 0 END,
                CASE WHEN ed.PointsChange < 0 THEN ABS(ed.PointsChange) ELSE 0 END,
                ed.USDValue,
                ed.ConversionRateSnapshot,
                ed.BalanceAfterTransaction
            FROM [DW].[Temp_EnrichedLoyaltyData] ed;
            
            SET @RowCount = @@ROWCOUNT;

            TRUNCATE TABLE [DW].[Temp_DailyLoyaltyTransactions];
            TRUNCATE TABLE [DW].[Temp_EnrichedLoyaltyData];

            UPDATE DW.ETL_Log 
            SET ChangeDescription = 'Load complete for date: ' + CONVERT(varchar, @CurrentDate, 101), 
                RowsAffected = @RowCount, 
                DurationSec = DATEDIFF(SECOND, @StartTime, SYSUTCDATETIME()), 
                Status = 'Success' 
            WHERE LogID = @LogID;

        END TRY
        BEGIN CATCH
            DECLARE @ErrMsg NVARCHAR(MAX) = ERROR_MESSAGE();
            UPDATE DW.ETL_Log 
            SET ChangeDescription = 'Load failed for date: ' + CONVERT(varchar, @CurrentDate, 101), 
                DurationSec = DATEDIFF(SECOND, @StartTime, SYSUTCDATETIME()), 
                Status = 'Error', 
                Message = @ErrMsg 
            WHERE LogID = @LogID;
            THROW;
        END CATCH

        SET @CurrentDate = DATEADD(day, 1, @CurrentDate);
    END;

    RAISERROR('FactLoyaltyPointTransaction_Transactional loading process has completed.', 0, 1) WITH NOWAIT;
    SET NOCOUNT OFF;
END
GO
