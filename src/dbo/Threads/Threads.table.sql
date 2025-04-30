CREATE TABLE dbo.Threads (
    ThreadId int NOT NULL IDENTITY,
    StartTime datetime NULL,
    CompleteTime datetime NULL,
    [Status] varchar(12) NOT NULL,
    ProcessId int NOT NULL,

    CONSTRAINT CH_Threads_Status
    CHECK ([Status] IN ('PLANNED', 'STARTED', 'COMPLETED', 'TERMINATED')),

    CONSTRAINT CH_Threads_Status_Planned
    CHECK ([Status] <> 'PLANNED'
        OR [Status] = 'PLANNED'
            AND StartTime IS NULL
            AND CompleteTime IS NULL),

    CONSTRAINT CH_Threads_Status_Started
    CHECK ([Status] <> 'STARTED'
        OR [Status] = 'STARTED'
            AND StartTime IS NOT NULL
            AND CompleteTime IS NULL),

    CONSTRAINT CH_Threads_Status_Completed
    CHECK ([Status] <> 'COMPLETED'
        OR [Status] = 'COMPLETED'
            AND StartTime IS NOT NULL
            AND CompleteTime IS NOT NULL),

    CONSTRAINT PK_Threads PRIMARY KEY (ThreadId)
);
GO
CREATE INDEX IX_Threads_ProcessId ON dbo.Threads (ProcessId ASC)
    INCLUDE (StartTime, CompleteTime, [Status]);