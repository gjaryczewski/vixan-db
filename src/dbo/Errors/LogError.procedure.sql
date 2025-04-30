CREATE PROCEDURE dbo.LogError
    @ProcessId int = NULL,
    @ThreadId int = NULL,
    @OperationId int = NULL,
    @ErrorLogId int = NULL OUTPUT AS
SET XACT_ABORT, NOCOUNT ON
BEGIN TRY
    DECLARE @ProcedureName nvarchar(128) = ERROR_PROCEDURE();
    DECLARE @LineNum int = ERROR_LINE();
    DECLARE @ErrorNum int = ERROR_NUMBER();
    DECLARE @ErrorMessage nvarchar(4000) = ERROR_MESSAGE();

    IF @OperationId IS NOT NULL AND @ThreadId IS NULL
        SET @ThreadId = (SELECT TOP(1) ThreadId FROM dbo.Operations WHERE OperationId = @OperationId);
    IF @ThreadId IS NOT NULL AND @ProcessId IS NULL
        SET @ProcessId = (SELECT TOP(1) ProcessId FROM dbo.Threads WHERE ThreadId = @ThreadId);

    INSERT dbo.ErrorLog (
        ProcessId,
        ThreadId,
        OperationId,
        ProcedureName,
        LineNum,
        ErrorNum,
        ErrorMessage
    ) VALUES (
        @ProcessId,
        @ThreadId,
        @OperationId,
        @ProcedureName,
        @LineNum,
        @ErrorNum,
        @ErrorMessage
    );

    SET @ErrorLogId = SCOPE_IDENTITY();
END TRY
BEGIN CATCH
    IF XACT_STATE() = -1 ROLLBACK TRANSACTION;
    THROW;
END CATCH