CREATE PROCEDURE dbo.RunOperation
    @OperationId int,
    @ThreadId int AS
SET XACT_ABORT, NOCOUNT ON
BEGIN TRY
    IF NOT EXISTS (SELECT * FROM dbo.Processes WHERE [Status] = 'STARTED')
        THROW 50001, 'No process is currently started.', 1;

    IF NOT EXISTS (SELECT * FROM dbo.Threads WHERE ThreadId = @ThreadId)
        THROW 50002, 'There is no thread with the given identifier.', 1;

    IF NOT EXISTS (SELECT * FROM dbo.Threads WHERE ThreadId = @ThreadId AND [Status] = 'STARTED')
        THROW 50003, 'The thread with the given identifier is not started.', 1;

    DECLARE @ProcessId int = (SELECT TOP(1) ProcessId FROM dbo.Threads WHERE ThreadId = @ThreadId);

    UPDATE dbo.Operations
        SET [Status] = 'STARTED',
            ThreadId = @ThreadId,
            ProcessId = @ProcessId,
            SessionId = @@SPID,
            StartTime = GETUTCDATE()
        WHERE OperationId = @OperationId
            AND [Status] = 'SCHEDULED';

    IF @@ROWCOUNT = 0
        THROW 50004, 'The operation is not available to start.', 1;

    INSERT dbo.OperationLog (OperationId, [Status]) VALUES (@OperationId, 'STARTED');

    DECLARE @ScriptName nvarchar(128) = (SELECT TOP(1) ScriptName FROM dbo.Operations WHERE OperationId = @OperationId);
    DECLARE @ScriptCode nvarchar(max) = (SELECT TOP(1) ScriptCode FROM dbo.Scripts WHERE ScriptName = @ScriptName);

    IF TRIM(ISNULL(@ScriptCode, '')) = ''
        THROW 50005, 'The configured script to run is empty.', 1;

    EXECUTE (@ScriptCode);

    UPDATE dbo.Operations
        SET [Status] = 'STOPPED',
            StopTime = GETUTCDATE()
        WHERE OperationId = @OperationId
        AND [Status] = 'STARTED';

    IF @@ROWCOUNT = 0
        THROW 50006, 'The operation is not available to stop.', 1;

    INSERT dbo.OperationLog (OperationId, [Status]) VALUES (@OperationId, 'STOPPED');
END TRY
BEGIN CATCH
   IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
   EXECUTE dbo.LogError @OperationId = @OperationId;
   RETURN 1;
END CATCH