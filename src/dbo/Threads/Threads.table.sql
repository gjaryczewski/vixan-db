CREATE TABLE dbo.Threads (
    ThreadId int NOT NULL IDENTITY,
    StartTime datetime NOT NULL
        CONSTRAINT DF_Threads_StartTime DEFAULT GETUTCDATE(),
    CompleteTime datetime NULL,
    [Status] varchar(12) NOT NULL,
    ProcessId int NOT NULL,

    CONSTRAINT CH_Threads_Status
    CHECK ([Status] IN ('STARTED', 'COMPLETED', 'TERMINATED')),

    CONSTRAINT CH_Threads_Status_Completed
    CHECK ([Status] <> 'COMPLETED'
        OR [Status] = 'COMPLETED'
            AND CompleteTime IS NOT NULL),

    CONSTRAINT CH_Threads_Status_Terminated
    CHECK ([Status] <> 'TERMINATED'
        OR [Status] = 'TERMINATED'
            AND CompleteTime IS NULL),

    CONSTRAINT PK_Threads PRIMARY KEY (ThreadId)
);
GO
CREATE INDEX IX_Threads_ProcessId ON dbo.Threads (ProcessId ASC)
    INCLUDE (StartTime, CompleteTime, [Status]);