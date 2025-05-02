CREATE TABLE dbo.Workers (
    WorkerId int NOT NULL IDENTITY,
    StartTime datetime NOT NULL
        CONSTRAINT DF_Workers_StartTime DEFAULT GETUTCDATE(),
    StopTime datetime NULL,
    [Status] varchar(12) NOT NULL,
    ProcessId int NOT NULL,

    CONSTRAINT CH_Workers_Status
    CHECK ([Status] IN ('STARTED', 'STOPPED', 'TERMINATED')),

    CONSTRAINT CH_Workers_Status_Stopped
    CHECK ([Status] <> 'STOPPED'
        OR [Status] = 'STOPPED'
            AND StopTime IS NOT NULL),

    CONSTRAINT CH_Workers_Status_Terminated
    CHECK ([Status] <> 'TERMINATED'
        OR [Status] = 'TERMINATED'
            AND StopTime IS NULL),

    CONSTRAINT PK_Workers PRIMARY KEY (WorkerId)
);
GO
CREATE INDEX IX_Workers_ProcessId ON dbo.Workers (ProcessId ASC)
    INCLUDE (StartTime, StopTime, [Status]);