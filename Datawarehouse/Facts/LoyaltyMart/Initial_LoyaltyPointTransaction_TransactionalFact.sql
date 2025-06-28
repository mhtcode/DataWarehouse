CREATE OR ALTER PROCEDURE [DW].[InitialFactLoyaltyPointTransaction]
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @StartDate date;
	DECLARE @EndDate date;

	-- Determine the date range from the loyalty transaction table.
	SELECT 
		@StartDate = MIN(CAST(TransactionDate AS DATE)),
		@EndDate = MAX(CAST(TransactionDate AS DATE))
	FROM 
		[SA].[PointsTransaction];

	IF @StartDate IS NULL
	BEGIN
		RAISERROR('No loyalty transactions found. Exiting procedure.', 0, 1) WITH NOWAIT;
		RETURN;
	END

	DECLARE @CurrentDate date = @StartDate;
	
	WHILE @CurrentDate <= @EndDate
	BEGIN
		DECLARE @LogID BIGINT;
		DECLARE @StartTime DATETIME2(3) = SYSUTCDATETIME();
		DECLARE @RowCount INT;

		INSERT INTO DW.ETL_Log (ProcedureName, TargetTable, ChangeDescription, ActionTime, Status) 
		VALUES ('InitialFactLoyaltyPointTransaction', 'FactLoyaltyPointTransaction_Transactional', 'Procedure started for date: ' + CONVERT(varchar, @CurrentDate, 101), @StartTime, 'Running');
		
		SET @LogID = SCOPE_IDENTITY();

		BEGIN TRY
			-- For idempotency, delete any records from the fact table for the date being processed.
			DELETE FROM [DW].[FactLoyaltyPointTransaction_Transactional]
			WHERE CAST([TransactionDateKey] AS DATE) = @CurrentDate;
			
			-- STEP A: Stage the daily loyalty transactions.
			INSERT INTO [DW].[Temp_DailyLoyaltyTransactions]
			SELECT 
                PointsTransactionID, AccountID, TransactionDate, LoyaltyTransactionTypeID, 
                PointsChange, BalanceAfterTransaction, USDValue, ConversionRate, 
                PointConversionRateID, ServiceOfferingID, FlightDetailID
			FROM [SA].[PointsTransaction]
			WHERE CAST(TransactionDate AS DATE) = @CurrentDate;

			IF @@ROWCOUNT = 0 
			BEGIN
				UPDATE DW.ETL_Log SET ChangeDescription = 'No loyalty transactions found for date: ' + CONVERT(varchar, @CurrentDate, 101), RowsAffected = 0, DurationSec = DATEDIFF(SECOND, @StartTime, SYSUTCDATETIME()), Status = 'Success' WHERE LogID = @LogID;
				SET @CurrentDate = DATEADD(day, 1, @CurrentDate);
				CONTINUE;
			END

			-- STEP B: Enrich the data by joining to dimensions and resolving SCD Type 2 keys.
			INSERT INTO [DW].[Temp_EnrichedLoyaltyData] (
                TransactionDateKey, PersonKey, AccountKey, LoyaltyTierKey, TransactionTypeKey, 
                ConversionRateKey, FlightKey, ServiceOfferingKey, PointsChange, USDValue, 
                ConversionRateSnapshot, BalanceAfterTransaction
            )
			SELECT
                -- Dimension Keys
				pt.TransactionDate,
				ISNULL(dp.PersonKey, -1),
				pt.AccountID,
				ISNULL(dlt.LoyaltyTierKey, -1),
				pt.LoyaltyTransactionTypeID,
				ISNULL(dcr.ConversionRateKey, -1),
				pt.FlightDetailID,
				ISNULL(dso.ServiceOfferingID, -1), -- The surrogate key for the service offering
                -- Measures for final calculation
                pt.PointsChange,
                pt.USDValue,
                ISNULL(dcr.Rate, 0),-- Get the rate from the dimension for historical accuracy
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
			-- Join for Service Offering (assuming not SCD Type 2)
			LEFT JOIN [DW].[DimServiceOffering] dso ON pt.ServiceOfferingID = dso.ServiceOfferingID;

			-- STEP C: Final Insert into the fact table, calculating earned/redeemed points.
			INSERT INTO [DW].[FactLoyaltyPointTransaction_Transactional] (
                TransactionDateKey, PersonKey, AccountKey, LoyaltyTierKey, TransactionTypeKey,
                ConversionRateKey, FlightKey, ServiceOfferingKey, PointsEarned, PointsRedeemed,
                USDValue, ConversionRateSnapshot, BalanceAfterTransaction
            )
			SELECT
				ed.TransactionDateKey, ed.PersonKey, ed.AccountKey, ed.LoyaltyTierKey, ed.TransactionTypeKey,
                ed.ConversionRateKey, ed.FlightKey, ed.ServiceOfferingKey,
                -- Calculated Measures
                CASE WHEN ed.PointsChange > 0 THEN ed.PointsChange ELSE 0 END,
                CASE WHEN ed.PointsChange < 0 THEN ABS(ed.PointsChange) ELSE 0 END,
                -- Direct Measures
                ed.USDValue,
                ed.ConversionRateSnapshot,
                ed.BalanceAfterTransaction
			FROM [DW].[Temp_EnrichedLoyaltyData] ed;
			
			SET @RowCount = @@ROWCOUNT;

			TRUNCATE TABLE [DW].[Temp_DailyLoyaltyTransactions];
			TRUNCATE TABLE [DW].[Temp_EnrichedLoyaltyData];

			UPDATE DW.ETL_Log SET ChangeDescription = 'Load complete for date: ' + CONVERT(varchar, @CurrentDate, 101), RowsAffected = @RowCount, DurationSec = DATEDIFF(SECOND, @StartTime, SYSUTCDATETIME()), Status = 'Success' WHERE LogID = @LogID;

		END TRY
		BEGIN CATCH
			DECLARE @ErrMsg NVARCHAR(MAX) = ERROR_MESSAGE();
			UPDATE DW.ETL_Log SET ChangeDescription = 'Load failed for date: ' + CONVERT(varchar, @CurrentDate, 101), DurationSec = DATEDIFF(SECOND, @StartTime, SYSUTCDATETIME()), Status = 'Error', Message = @ErrMsg WHERE LogID = @LogID;
			THROW;
		END CATCH

		SET @CurrentDate = DATEADD(day, 1, @CurrentDate);
	END;

	RAISERROR('InitialFactLoyaltyPointTransaction loading process has completed.', 0, 1) WITH NOWAIT;
	SET NOCOUNT OFF;
END
GO

SELECT 
    PointsTransactionID,
    TransactionDate,
    PointConversionRateID 
FROM 
    SA.PointsTransaction
WHERE 
    PointsTransactionID = 1;