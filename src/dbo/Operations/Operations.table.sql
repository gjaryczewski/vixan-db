CREATE TABLE dbo.Operations (
    OperationId int NOT NULL IDENTITY,
    ScriptName nvarchar(128) NOT NULL,
    StartTime datetime NULL,
    CompleteTime datetime NULL,
    [Status] varchar(12) NOT NULL,
    WorkerId int NULL,
    ProcessId int NOT NULL,
    SessionId int NULL,

    CONSTRAINT CH_Operations_Status
    CHECK ([Status] IN ('PLANNED', 'STARTED', 'COMPLETED', 'TERMINATING', 'TERMINATED')),

    CONSTRAINT CH_Operations_Status_Planned
    CHECK ([Status] <> 'PLANNED'
        OR [Status] = 'PLANNED'
            AND StartTime IS NULL
            AND CompleteTime IS NULL
            AND WorkerId IS NULL
            AND SessionId IS NULL),

    CONSTRAINT CH_Operations_Status_Started
    CHECK ([Status] <> 'STARTED'
        OR [Status] = 'STARTED'
            AND StartTime IS NOT NULL
            AND CompleteTime IS NULL
            AND WorkerId IS NOT NULL
            AND SessionId IS NOT NULL),

    CONSTRAINT CH_Operations_Status_Completed
    CHECK ([Status] <> 'COMPLETED'
        OR [Status] = 'COMPLETED'
            AND StartTime IS NOT NULL
            AND CompleteTime IS NOT NULL
            AND WorkerId IS NOT NULL
            AND SessionId IS NOT NULL),

    CONSTRAINT PK_Operations PRIMARY KEY (OperationId)
);
GO
CREATE INDEX IX_Operations_WorkerId_Include ON dbo.Operations (WorkerId ASC)
    INCLUDE ([Status]);
GO
CREATE INDEX IX_Operations_ProcessId_Include ON dbo.Operations (ProcessId ASC);