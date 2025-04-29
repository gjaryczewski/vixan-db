CREATE TABLE dbo.ThreadLog (
    Id int NOT NULL IDENTITY,
    LogTime datetime NOT NULL
        CONSTRAINT DF_ThreadLog_LogTime DEFAULT GETUTCDATE(),

    ThreadId int NOT NULL,
    [Status] varchar(12) NOT NULL,

    UserLogin nvarchar(128) NULL
        CONSTRAINT DF_ThreadLog_UserLogin DEFAULT SYSTEM_USER,
    UserHost  nvarchar(128) NULL
        CONSTRAINT DF_ThreadLog_UserHost DEFAULT HOST_NAME(),

    CONSTRAINT PK_ThreadLog PRIMARY KEY (Id)
    WITH (OPTIMIZE_FOR_SEQUENTIAL_KEY = ON)
);
GO
CREATE INDEX IX_ThreadLog_LogTime ON dbo.ThreadLog (LogTime ASC);
GO
CREATE INDEX IX_ThreadLog_ThreadId ON dbo.ThreadLog (ThreadId ASC);