CREATE PROCEDURE dbo.StartThread
    @ThreadId int = null OUT AS
SET XACT_ABORT, NOCOUNT ON
BEGIN TRY
    IF NOT EXISTS (SELECT * FROM dbo.Processes WHERE [Status] = 'STARTED')
        THROW 50001, 'No process is currently started.', 1;

    DECLARE @ProcessId int = (
        SELECT TOP(1) ProcessId FROM dbo.Processes WHERE [Status] = 'STARTED');

    INSERT dbo.Threads (ProcessId, [Status]) VALUES (@ProcessId, 'STARTED');

    SET @ThreadId = SCOPE_IDENTITY();

    INSERT dbo.ThreadLog (ThreadId, [Status]) VALUES (@ThreadId, 'STARTED');
END TRY
BEGIN CATCH
   IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
   EXECUTE dbo.LogError @ThreadId = @ThreadId;
   RETURN 1;
END CATCH