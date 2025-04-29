CREATE TABLE dbo.OperationLog (
    Id int NOT NULL IDENTITY,
    LogTime datetime NOT NULL
        CONSTRAINT DF_OperationLog_LogTime DEFAULT GETUTCDATE(),

    OperationId int NOT NULL,
    [Status] varchar(12) NOT NULL,

    UserLogin nvarchar(128) NULL
        CONSTRAINT DF_OperationLog_UserLogin DEFAULT SYSTEM_USER,
    UserHost  nvarchar(128) NULL
        CONSTRAINT DF_OperationLog_UserHost DEFAULT HOST_NAME(),

    CONSTRAINT PK_OperationLog PRIMARY KEY (Id)
    WITH (OPTIMIZE_FOR_SEQUENTIAL_KEY = ON)
);
GO
CREATE INDEX IX_OperationLog_LogTime ON dbo.OperationLog (LogTime ASC);
GO
CREATE INDEX IX_OperationLog_OperationId ON dbo.OperationLog (OperationId ASC);