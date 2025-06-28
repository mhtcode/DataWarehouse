CREATE OR ALTER PROCEDURE [DW].[Main_Fact_Initial_ETL]
AS
BEGIN
    SET NOCOUNT ON;

    -- List of all Initial Fact ETL procedures
    DECLARE @procs TABLE (ProcName NVARCHAR(128));
    INSERT INTO @procs (ProcName) VALUES
        (N'Initial_FlightOperation_Factless'),
        (N'Initial_PassengerActivity_ACCFact'),
        (N'Initial_PassengerTicket_TransactionalFact'),
        (N'Initial_PassengerActivity_YearlyFact'),

        (N'Initial_LoyaltyPoint_TransactionalFact'),
        (N'Initial_CrewAssignmentEvent_Factless'),
        (N'Initial_PersonPointTransactions_MonthlyFact'),
        (N'Initial_PersonPointTransactions_ACCFact'),

        (N'Initial_AircraftHealth_MonthlyFact'),
        (N'Initial_MaintenanceEvent_TransactionalFact'),
        (N'Initial_PartReplacement_TransactionalFact'),

        (N'Initial_FlightPerformance_TransactionalFact'),
        (N'Initial_FlightDelay_DailyFact'),
        (N'Initial_FlightDelay_ACCFact'),
        (N'Initial_AirlineAndAirport_Factless');

    DECLARE @ProcName NVARCHAR(128), @sql NVARCHAR(300);

    DECLARE proc_cursor CURSOR FOR SELECT ProcName FROM @procs;
    OPEN proc_cursor;
    FETCH NEXT FROM proc_cursor INTO @ProcName;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Check existence and run
        IF OBJECT_ID(N'DW.' + @ProcName, 'P') IS NOT NULL
        BEGIN
            PRINT N'Executing: [DW].[' + @ProcName + N']...';
            SET @sql = N'EXEC [DW].[' + @ProcName + N']';
            EXEC sp_executesql @sql;
        END
        ELSE
        BEGIN
            PRINT N'Skipped: [DW].[' + @ProcName + N'] does not exist.';
        END
        FETCH NEXT FROM proc_cursor INTO @ProcName;
    END
    CLOSE proc_cursor;
    DEALLOCATE proc_cursor;

    PRINT N'All available Initial Fact ETL procedures have been executed.';
END
GO

-- To run all Initial Fact ETLs at once:
EXEC [DW].[Main_Fact_Initial_ETL];
GO
