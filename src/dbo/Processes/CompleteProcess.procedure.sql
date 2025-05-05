CREATE PROCEDURE dbo.CompleteProcess AS
SET XACT_ABORT, NOCOUNT ON
BEGIN TRY
    IF NOT EXISTS (SELECT * FROM dbo.CurrentProcess)
        THROW 50001, 'No process is currently started.', 1;

    DECLARE @ProcessId int = (SELECT TOP(1) ProcessId FROM dbo.CurrentProcess);

    IF EXISTS (SELECT * FROM dbo.Workers WHERE ProcessId = @ProcessId AND [Status] IN ('PLANNED', 'STARTED'))
        THROW 50003, 'The process cannot be completed because some workers are scheduled or have already started.', 1;

    UPDATE dbo.Processes
        SET [Status] = 'COMPLETED',
            CompleteTime = GETUTCDATE()
        WHERE ProcessId = @ProcessId
            AND [Status] = 'STARTED';

    IF @@ROWCOUNT = 0
        THROW 50005, 'The process is not ready to complete.', 1;

    INSERT dbo.ProcessLog (ProcessId, [Status]) VALUES (@ProcessId, 'COMPLETED');
END TRY
BEGIN CATCH
   IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
   EXECUTE dbo.LogError @ProcessId = @ProcessId;
   RETURN 1;
END CATCH