CREATE PROCEDURE dbo.CompleteThread
    @ThreadId int AS
SET XACT_ABORT, NOCOUNT ON
BEGIN TRY
    IF NOT EXISTS (SELECT * FROM dbo.Processes WHERE [Status] = 'STARTED')
        THROW 50001, 'No process is currently started.', 1;

    IF NOT EXISTS (SELECT * FROM dbo.Threads WHERE ThreadId = @ThreadId)
        THROW 50002, 'There is no thread with the given identifier.', 1;

    IF EXISTS (SELECT * FROM dbo.Threads WHERE ThreadId = @ThreadId AND [Status] IN ('COMPLETED', 'TERMINATED'))
        THROW 50003, 'The thread is already completed or terminated.', 1;

    IF EXISTS (SELECT * FROM dbo.Operations WHERE ThreadId = @ThreadId AND [Status] IN ('PLANNED', 'STARTED'))
        THROW 50004, 'The thread cannot be completed because some operations are scheduled or have already started.', 1;

    UPDATE dbo.Threads
        SET [Status] = 'COMPLETED',
            CompleteTime = GETUTCDATE()
        WHERE ThreadId = @ThreadId
            AND [Status] = 'STARTED';

    IF @@ROWCOUNT = 0
        THROW 50005, 'The process is not available to complete.', 1;

    INSERT dbo.ThreadLog (ThreadId, [Status]) VALUES (@ThreadId, 'COMPLETED');
END TRY
BEGIN CATCH
   IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
   EXECUTE dbo.LogError @ThreadId = @ThreadId;
   RETURN 1;
END CATCH