CREATE TABLE [DW].[ETL_Log] (
  [LogID]             BIGINT            IDENTITY(1,1) NOT NULL PRIMARY KEY,
  [ProcedureName]     NVARCHAR(255)     NOT NULL,         -- e.g. 'usp_LoadDimPerson_Initial'
  [TargetTable]       NVARCHAR(255)     NOT NULL,         -- e.g. 'DimPerson'
  [ChangeDescription] NVARCHAR(MAX)     NULL,             -- free-form description of what the proc did
  [RowsAffected]      INT               NULL,             -- number of rows inserted/updated/deleted
  [ActionTime]        DATETIME2(3)      NOT NULL  
    DEFAULT SYSUTCDATETIME(),                            -- when the action occurred
  [DurationSec]       DECIMAL(9,3)      NULL,             -- elapsed time in seconds
  [Status]            NVARCHAR(50)      NULL,             -- e.g. 'Success', 'Error'
  [Message]           NVARCHAR(MAX)     NULL              -- any error or informational message
);
GO
