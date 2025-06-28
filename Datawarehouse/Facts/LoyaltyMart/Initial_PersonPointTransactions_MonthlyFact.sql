CREATE OR ALTER PROCEDURE [DW].[Initial_PersonPointTransactions_MonthlyFact]
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @LogID BIGINT;
	DECLARE @StartTime DATETIME2(3) = SYSUTCDATETIME();
	DECLARE @RowCount INT;

	INSERT INTO DW.ETL_Log (ProcedureName, TargetTable, ChangeDescription, ActionTime, Status) 
	VALUES ('Initial_PersonPointTransactions_MonthlyFact', 'PersonPointTransactions_MonthlyFact', 'Procedure started for initial full load', @StartTime, 'Running');
		
	SET @LogID = SCOPE_IDENTITY();

	BEGIN TRY
		-- CTE to aggregate all transactions, grouped by month and historical dimension keys.
		WITH MonthlyAggregates AS (
			SELECT
                DATEFROMPARTS(YEAR(fact.TransactionDateKey), MONTH(fact.TransactionDateKey), 1) AS MonthStart,
				fact.PersonKey AS HistoricalPersonKey,
				fact.LoyaltyTierKey AS HistoricalLoyaltyTierKey,
				SUM(fact.PointsEarned) AS MonthlyPointsEarned,
				SUM(fact.PointsRedeemed) AS MonthlyPointsRedeemed,
                SUM(fact.CurrencyValue) AS MonthlyPointValueUSD,
				COUNT(*) AS MonthlyNumberOfTransactions,
				COUNT(DISTINCT fact.FlightKey) AS MonthlyDistinctFlightsEarnedOn
			FROM
				[DW].[LoyaltyPointTransaction_TransactionalFact] fact
			GROUP BY
				DATEFROMPARTS(YEAR(fact.TransactionDateKey), MONTH(fact.TransactionDateKey), 1),
				fact.PersonKey,
				fact.LoyaltyTierKey
		)
		-- Final insert for the initial load
		INSERT INTO [DW].[PersonPointTransactions_MonthlyFact] (
			MonthID, PersonKey, LoyaltyTierKey, MonthlyPointsEarned, MonthlyPointsRedeemed,
			NetPointChange, MonthlyPointValueUSD, MonthlyNumberOfTransactions, MonthlyDistinctFlightsEarnedOn
		)
		SELECT
			agg.MonthStart,
			ISNULL(person_eom.PersonKey, -1),
            ISNULL(tier_eom.LoyaltyTierKey, -1),
			agg.MonthlyPointsEarned,
			agg.MonthlyPointsRedeemed,
			agg.MonthlyPointsEarned - agg.MonthlyPointsRedeemed,
			agg.MonthlyPointValueUSD,
			agg.MonthlyNumberOfTransactions,
			agg.MonthlyDistinctFlightsEarnedOn
		FROM 
			MonthlyAggregates agg
		LEFT JOIN [DW].[DimPerson] historical_person ON agg.HistoricalPersonKey = historical_person.PersonKey
		LEFT JOIN [DW].[DimPerson] person_eom ON historical_person.PersonID = person_eom.PersonID
            AND EOMONTH(agg.MonthStart) >= person_eom.EffectiveFrom 
			AND EOMONTH(agg.MonthStart) < ISNULL(person_eom.EffectiveTo, '9999-12-31')
        LEFT JOIN [DW].[DimLoyaltyTier] historical_tier ON agg.HistoricalLoyaltyTierKey = historical_tier.LoyaltyTierKey
        LEFT JOIN [DW].[DimLoyaltyTier] tier_eom ON historical_tier.LoyaltyTierID = tier_eom.LoyaltyTierID
            AND EOMONTH(agg.MonthStart) >= tier_eom.EffectiveFrom
            AND EOMONTH(agg.MonthStart) < ISNULL(tier_eom.EffectiveTo, '9999-12-31');

		SET @RowCount = @@ROWCOUNT;

		UPDATE DW.ETL_Log SET ChangeDescription = 'Initial full load complete', RowsAffected = @RowCount, DurationSec = DATEDIFF(SECOND, @StartTime, SYSUTCDATETIME()), Status = 'Success' WHERE LogID = @LogID;

	END TRY
	BEGIN CATCH
		DECLARE @ErrMsg NVARCHAR(MAX) = ERROR_MESSAGE();
		UPDATE DW.ETL_Log SET ChangeDescription = 'Initial full load failed', DurationSec = DATEDIFF(SECOND, @StartTime, SYSUTCDATETIME()), Status = 'Error', Message = @ErrMsg WHERE LogID = @LogID;
		THROW;
	END CATCH

	RAISERROR('Initial PersonPointTransactions_MonthlyFact loading process has completed.', 0, 1) WITH NOWAIT;
	SET NOCOUNT OFF;
END
GO