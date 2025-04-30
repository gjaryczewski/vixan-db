CREATE TABLE dbo.Processes (
    ProcessId int NOT NULL IDENTITY,
    StartTime datetime NOT NULL
        CONSTRAINT DF_Processes_StartTime DEFAULT GETUTCDATE(),
    StopTime datetime NULL,
    [Status] varchar(12) NOT NULL,

    CONSTRAINT CH_Processes_Status
    CHECK ([Status] IN ('STARTING', 'STARTED', 'CANCELING', 'STOPPED', 'TERMINATING', 'CANCELED')),

    CONSTRAINT CH_Processes_StopTime
    CHECK ([Status] <> 'STOPPED'
            AND StopTime IS NULL
        OR [Status] = 'STOPPED'
            AND StopTime IS NOT NULL),

    CONSTRAINT PK_Processes PRIMARY KEY (ProcessId)
);
GO
CREATE UNIQUE INDEX IX_Processes_Status_Started ON dbo.Processes ([Status])
    INCLUDE (StartTime, StopTime)
    WHERE [Status] = 'STARTED';