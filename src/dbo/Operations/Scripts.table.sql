CREATE TABLE dbo.Scripts
(
    ScriptName nvarchar(128) NOT NULL,
    ScriptCode nvarchar(max) NOT NULL,
    SeqNum int NOT NULL,

    SysValidFrom DATETIME2 GENERATED ALWAYS AS ROW START NOT NULL,
    SysValidTo DATETIME2 GENERATED ALWAYS AS ROW END NOT NULL,
    PERIOD FOR SYSTEM_TIME (SysValidFrom, SysValidTo),

    CONSTRAINT CH_Scripts_SeqNum
    CHECK (SeqNum > 0),

    CONSTRAINT PK_Scripts PRIMARY KEY (ScriptName ASC)
)
WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo.ScriptsHistory));
GO
CREATE INDEX IX_Scrips_SeqNum_ScriptName ON dbo.Scripts (SeqNum ASC, ScriptName ASC);