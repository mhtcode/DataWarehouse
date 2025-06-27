CREATE TABLE [SA].[ETL_Log] (
    [LogID]             BIGINT            IDENTITY(1,1) NOT NULL PRIMARY KEY,
    [ProcedureName]     NVARCHAR(255)     NOT NULL,    -- e.g. 'ETL_FlightOperation'
    [SourceTable]       NVARCHAR(255)     NOT NULL,    -- e.g. 'Source.FlightOperation'
    [TargetTable]       NVARCHAR(255)     NOT NULL,    -- e.g. 'SA.FlightOperation'
    [ChangeDescription] NVARCHAR(MAX)     NULL,        -- free-form description of what happened
    [RowsAffected]      INT               NULL,        -- number of rows inserted/updated/deleted
    [ActionTime]        DATETIME2(3)      NOT NULL DEFAULT SYSUTCDATETIME(),
    [DurationSec]       DECIMAL(9,3)      NULL,        -- elapsed time in seconds
    [Status]            NVARCHAR(50)      NULL,        -- e.g. 'Started','Success','Error'
    [Message]           NVARCHAR(MAX)     NULL         -- error or informational message
);
GO