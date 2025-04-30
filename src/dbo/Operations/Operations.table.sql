CREATE TABLE dbo.Operations (
    OperationId int NOT NULL IDENTITY,
    ScriptName nvarchar(128) NOT NULL,
    StartTime datetime NULL,
    StopTime datetime NULL,
    [Status] varchar(12) NOT NULL,
    ThreadId int NULL,
    ProcessId int NOT NULL,
    SessionId int NULL,

    CONSTRAINT CH_Operations_Status
    CHECK ([Status] IN ('SCHEDULED', 'STARTED', 'STOPPED', 'CANCELED')),

    CONSTRAINT CH_Operations_Status_Scheduled
    CHECK ([Status] <> 'SCHEDULED'
        OR [Status] = 'SCHEDULED'
            AND StartTime IS NULL
            AND StopTime IS NULL
            AND ThreadId IS NULL
            AND SessionId IS NULL),

    CONSTRAINT CH_Operations_Status_Started
    CHECK ([Status] <> 'STARTED'
        OR [Status] = 'STARTED'
            AND StartTime IS NOT NULL
            AND StopTime IS NULL
            AND ThreadId IS NOT NULL
            AND SessionId IS NOT NULL),

    CONSTRAINT CH_Operations_Status_Stopped
    CHECK ([Status] <> 'STOPPED'
        OR [Status] = 'STOPPED'
            AND StartTime IS NOT NULL
            AND StopTime IS NOT NULL
            AND ThreadId IS NOT NULL
            AND SessionId IS NOT NULL),

    CONSTRAINT PK_Operations PRIMARY KEY (OperationId)
);
GO
CREATE INDEX IX_Operations_ThreadId_Include ON dbo.Operations (ThreadId ASC)
    INCLUDE ([Status]);
GO
CREATE INDEX IX_Operations_ProcessId_Include ON dbo.Operations (ProcessId ASC);