CREATE PROCEDURE dbo.TerminateOperation
    @OperationId int AS
SET XACT_ABORT, NOCOUNT ON
BEGIN TRY
    IF NOT EXISTS (SELECT * FROM dbo.CurrentProcess)
        THROW 50001, 'No process is currently started.', 1;

    IF NOT EXISTS (SELECT * FROM dbo.CurrentOperations WHERE OperationId = @OperationId)
        THROW 50002, 'There is no current operation with the given identifier.', 1;

    IF EXISTS (SELECT * FROM dbo.CurrentOperations WHERE OperationId = @OperationId AND [Status] IN ('COMPLETED', 'TERMINATED'))
        THROW 50003, 'The operation is already completed or terminated.', 1;

    IF EXISTS (SELECT * FROM dbo.CurrentOperations WHERE OperationId = @OperationId AND [Status] = 'STARTED')
    BEGIN
        UPDATE dbo.Operations SET [Status] = 'TERMINATING' WHERE OperationId = @OperationId;

        INSERT dbo.OperationLog (OperationId, [Status]) VALUES (@OperationId, 'TERMINATING');

        DECLARE @SessionId int = (SELECT TOP(1) SessionId FROM dbo.Operations WHERE OperationId = @OperationId);
        IF EXISTS (SELECT * FROM sys.dm_exec_sessions WHERE [session_id] = @SessionId) 
        BEGIN
            DECLARE @KillScript varchar(100) = CONCAT('KILL ', @SessionId);
            EXECUTE (@KillScript);
        END

        WAITFOR DELAY '00:00:01';

        IF EXISTS (SELECT * FROM sys.dm_exec_sessions WHERE [session_id] = @SessionId) 
            THROW 5004, 'The session assigned to the operation cannot be properly terminated.', 1;
    END

    UPDATE dbo.Operations SET [Status] = 'TERMINATED' WHERE OperationId = @OperationId;

    INSERT dbo.OperationLog (OperationId, [Status]) VALUES (@OperationId, 'TERMINATED');
END TRY
BEGIN CATCH
   IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
   EXECUTE dbo.LogError @OperationId = @OperationId;
   RETURN 1;
END CATCH