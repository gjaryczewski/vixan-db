CREATE TABLE dbo.Threads (
    Id int NOT NULL IDENTITY,
    StartTime datetime NOT NULL,
    StopTime datetime NULL,
    [Status] varchar(12) NOT NULL,
    ProcessId int NOT NULL,

    CONSTRAINT CH_Threads_Status
    CHECK ([Status] IN ('SCHEDULED', 'STARTED', 'STOPPED', 'CANCELED')),

    CONSTRAINT CH_Threads_Status_Scheduled
    CHECK ([Status] <> 'SCHEDULED'
        OR [Status] = 'SCHEDULED'
            AND StartTime IS NULL
            AND StopTime IS NULL
            AND ProcessId IS NULL),

    CONSTRAINT CH_Threads_Status_Started
    CHECK ([Status] <> 'STARTED'
        OR [Status] = 'STARTED'
            AND StartTime IS NOT NULL
            AND StopTime IS NULL
            AND ProcessId IS NOT NULL),

    CONSTRAINT CH_Threads_Status_Stopped
    CHECK ([Status] <> 'STOPPED'
        OR [Status] = 'STOPPED'
            AND StartTime IS NOT NULL
            AND StopTime IS NOT NULL
            AND ProcessId IS NOT NULL),

    CONSTRAINT PK_Threads PRIMARY KEY (Id)
);
GO
CREATE INDEX IX_Threads_ProcessId ON dbo.Threads (ProcessId ASC)
    INCLUDE (StartTime, StopTime, [Status]);