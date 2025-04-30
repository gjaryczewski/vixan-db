CREATE TABLE dbo.ErrorLog (
    ErrorLogId int NOT NULL IDENTITY,
    LogTime datetime NOT NULL
        CONSTRAINT DF_ErrorLog_LogTime DEFAULT GETUTCDATE(),

    ProcessId int NULL,
    ThreadId int NULL,
    OperationId int NULL,
    ProcedureName nvarchar(128) NULL,
    LineNum int NULL,
    ErrorNum int NULL,
    ErrorMessage nvarchar(4000),

    UserLogin nvarchar(128) NULL
        CONSTRAINT DF_ErrorLog_UserLogin DEFAULT SYSTEM_USER,
    UserHost  nvarchar(128) NULL
        CONSTRAINT DF_ErrorLog_UserHost DEFAULT HOST_NAME(),

    CONSTRAINT PK_ErrorLog PRIMARY KEY (ErrorLogId)
    WITH (OPTIMIZE_FOR_SEQUENTIAL_KEY = ON)
);
GO
CREATE INDEX IX_ErrorLog_LogTime ON dbo.ErrorLog (LogTime ASC);
GO
CREATE INDEX IX_ErrorLog_ProcessId ON dbo.ErrorLog (ProcessId ASC);
GO
CREATE INDEX IX_ErrorLog_ThreadId ON dbo.ErrorLog (ThreadId ASC);
GO
CREATE INDEX IX_ErrorLog_OperationId ON dbo.ErrorLog (OperationId ASC);