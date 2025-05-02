USE [master];

IF '$(EnvironmentName)' = 'Local' AND EXISTS (SELECT * FROM sys.databases WHERE [name] = '$(DatabaseName)')
BEGIN
    PRINT 'Dropping sessions to $(DatabaseName)';
    DECLARE @Script varchar(100) = '';
    DECLARE @I int = 1;
    WHILE EXISTS (SELECT * FROM sys.dm_exec_sessions WHERE database_id = DB_ID('$(DatabaseName)'))
    BEGIN
        SET @Script = (
            SELECT TOP(1) CONCAT('KILL ', session_id)
            FROM sys.dm_exec_sessions
            WHERE database_id = DB_ID('$(DatabaseName)'));

        EXECUTE (@Script);

        SET @I += 1;
        IF @I > 1000
        BEGIN
            RAISERROR ('The breaking sessions loop terminated after 1000 executions.', 10, 1) WITH NOWAIT;
            BREAK;
        END
    END

    PRINT 'Dropping database $(DatabaseName)';
    DROP DATABASE [$(DatabaseName)];
END