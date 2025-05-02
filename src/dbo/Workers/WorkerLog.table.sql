CREATE TABLE dbo.WorkerLog (
    WorkerLogId int NOT NULL IDENTITY,
    LogTime datetime NOT NULL
        CONSTRAINT DF_WorkerLog_LogTime DEFAULT GETUTCDATE(),

    WorkerId int NOT NULL,
    [Status] varchar(12) NOT NULL,

    UserLogin nvarchar(128) NOT NULL
        CONSTRAINT DF_WorkerLog_UserLogin DEFAULT SYSTEM_USER,
    UserHost  nvarchar(128) NOT NULL
        CONSTRAINT DF_WorkerLog_UserHost DEFAULT HOST_NAME(),

    CONSTRAINT PK_WorkerLog PRIMARY KEY (WorkerLogId)
    WITH (OPTIMIZE_FOR_SEQUENTIAL_KEY = ON)
);
GO
CREATE INDEX IX_WorkerLog_LogTime ON dbo.WorkerLog (LogTime ASC);
GO
CREATE INDEX IX_WorkerLog_WorkerId ON dbo.WorkerLog (WorkerId ASC);