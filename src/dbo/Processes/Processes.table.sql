CREATE TABLE dbo.Processes (
    ProcessId int NOT NULL IDENTITY,
    StartTime datetime NOT NULL
        CONSTRAINT DF_Processes_StartTime DEFAULT GETUTCDATE(),
    CompleteTime datetime NULL,
    [Status] varchar(12) NOT NULL,

    CONSTRAINT CH_Processes_Status
    CHECK ([Status] IN ('STARTING', 'STARTED', 'TERMINATING', 'COMPLETED', 'TERMINATING', 'TERMINATED')),

    CONSTRAINT CH_Processes_CompleteTime
    CHECK ([Status] <> 'COMPLETED'
            AND CompleteTime IS NULL
        OR [Status] = 'COMPLETED'
            AND CompleteTime IS NOT NULL),

    CONSTRAINT PK_Processes PRIMARY KEY (ProcessId)
);
GO
CREATE UNIQUE INDEX IX_Processes_Status_Started ON dbo.Processes ([Status])
    INCLUDE (StartTime, CompleteTime)
    WHERE [Status] = 'STARTED';