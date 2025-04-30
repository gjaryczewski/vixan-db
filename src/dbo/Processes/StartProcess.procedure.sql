CREATE PROCEDURE dbo.StartProcess
    @ThreadsNum int = 1,
    @ProcessId int = NULL OUTPUT AS
SET XACT_ABORT, NOCOUNT ON
BEGIN TRY
    IF EXISTS (SELECT * FROM dbo.Processes WHERE [Status] = 'STARTED')
        THROW 50001, 'Another process is already started.', 1;

    IF (@ThreadsNum < 1 OR @ThreadsNum > 64)
        THROW 50002, 'The number of threads to be scheduled must be selected from the range of 1 to 64.', 1;

    INSERT dbo.Processes ([Status]) VALUES ('STARTING');

    SET @ProcessId = SCOPE_IDENTITY();

    INSERT dbo.ProcessLog (ProcessId, [Status]) VALUES (@ProcessId, 'STARTING');

    INSERT dbo.Operations (ProcessId, ScriptName, [Status])
        SELECT @ProcessId, ScriptName, 'SCHEDULED'
        FROM dbo.Scripts
        ORDER BY SeqNum ASC, ScriptName ASC;

    INSERT dbo.Threads (ProcessId, [Status])
        SELECT @ProcessId, 'SCHEDULED'
        FROM GENERATE_SERIES(1, @ThreadsNum);

    UPDATE dbo.Processes SET [Status] = 'STARTED' WHERE ProcessId = @ProcessId;

    INSERT dbo.ProcessLog (ProcessId, [Status]) VALUES (@ProcessId, 'STARTED');
END TRY
BEGIN CATCH
   IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
   EXECUTE dbo.LogError @ProcessId = @ProcessId;
   RETURN 1;
END CATCH