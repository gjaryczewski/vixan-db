CREATE PROCEDURE dbo.StartThread
    @ThreadId int AS
SET XACT_ABORT, NOCOUNT ON
BEGIN TRY
    IF NOT EXISTS (SELECT * FROM dbo.Processes WHERE [Status] = 'STARTED')
        THROW 50001, 'No process is currently started.', 1;

    DECLARE @ProcessId int = (
        SELECT TOP(1) ProcessId FROM dbo.Processes WHERE [Status] = 'STARTED');

    UPDATE dbo.Threads
        SET [Status] = 'STARTED',
            ProcessId = @ProcessId,
            StartTime = GETUTCDATE()
        WHERE ThreadId = @ThreadId
            AND [Status] = 'PLANNED';

    IF @@ROWCOUNT = 0
        THROW 50002, 'The thread is not available to start.', 1;

    INSERT dbo.ThreadLog (ThreadId, [Status]) VALUES (@ThreadId, 'STARTED');
END TRY
BEGIN CATCH
   IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
   EXECUTE dbo.LogError @ThreadId = @ThreadId;
   RETURN 1;
END CATCH