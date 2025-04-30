CREATE TABLE dbo.ProcessLog (
    ProcessLogId int NOT NULL IDENTITY,
    LogTime datetime NOT NULL
        CONSTRAINT DF_ProcessLog_LogTime DEFAULT GETUTCDATE(),

    ProcessId int NOT NULL,
    [Status] varchar(12) NOT NULL,

    UserLogin nvarchar(128) NULL
        CONSTRAINT DF_ProcessLog_UserLogin DEFAULT SYSTEM_USER,
    UserHost  nvarchar(128) NULL
        CONSTRAINT DF_ProcessLog_UserHost DEFAULT HOST_NAME(),

    CONSTRAINT PK_ProcessLog PRIMARY KEY (ProcessLogId)
    WITH (OPTIMIZE_FOR_SEQUENTIAL_KEY = ON)
);
GO
CREATE INDEX IX_ProcessLog_LogTime ON dbo.ProcessLog (LogTime ASC);
GO
CREATE INDEX IX_ProcessLog_ProcessId ON dbo.ProcessLog (ProcessId ASC);