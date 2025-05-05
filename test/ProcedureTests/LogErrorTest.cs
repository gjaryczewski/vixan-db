using Vixan.Db.Test.Fixtures;

namespace Vixan.Db.Test.ProcedureTests;

[Collection("Sequential")]
public class LogErrorTest
{
    [Fact]
    public void LogError_Captures_Error_Attributtes_When_Running_Nonprocedural_Script()
    {
        // Arrange
        DbFixture.Reset();
        var startTime = DbFixture.GetTimeUc();
        var procedureName = (string?)null;
        var errorNum = 50001;
        var errorMessage = "A test error message.";

        // Act
        DbFixture.Execute($"""
            BEGIN TRY
                THROW {errorNum}, '{errorMessage}', 1;
            END TRY
            BEGIN CATCH
                EXECUTE dbo.LogError;
            END CATCH
            """);

        // Assert
        var logEntries = DbFixture.GetErrorLogSince(startTime);
        Assert.NotNull(logEntries);
        Assert.Single(logEntries);
        var entry = logEntries.First();
        Assert.Equivalent(
            new { ProcedureName = procedureName, ErrorNum = errorNum, ErrorMessage = errorMessage },
            new { entry.ProcedureName, entry.ErrorNum, entry.ErrorMessage });
    }

    [Fact]
    public void LogError_Captures_Error_Attributtes_When_Running_Procedure()
    {
        // Arrange
        DbFixture.Reset();
        var startTime = DbFixture.GetTimeUc();
        var procedureName = (string?)"dbo.ProcedureWithError";
        var errorNum = 50001;
        var errorMessage = "A test error message.";
        DbFixture.Execute($"DROP PROCEDURE IF EXISTS {procedureName}");
        DbFixture.Execute($"""
            CREATE PROCEDURE {procedureName} AS
            BEGIN TRY
                THROW {errorNum}, '{errorMessage}', 1;
            END TRY
            BEGIN CATCH
                EXECUTE dbo.LogError;
            END CATCH
            """);

        // Act
        DbFixture.Execute($"EXECUTE {procedureName}");

        // Assert
        var logEntries = DbFixture.GetErrorLogSince(startTime);
        Assert.NotNull(logEntries);
        Assert.Single(logEntries);
        var entry = logEntries.First();
        Assert.Equivalent(
            new { ProcedureName = procedureName, ErrorNum = errorNum, ErrorMessage = errorMessage },
            new { entry.ProcedureName, entry.ErrorNum, entry.ErrorMessage });

        // Cleanup
        DbFixture.Execute($"DROP PROCEDURE IF EXISTS {procedureName}");
    }

    [Fact]
    public void LogError_Stores_OperationId_WorkerId_ProcessId_If_Operation_Fails()
    {
        // Arrange
        DbFixture.Reset();
        var startTime = DbFixture.GetTimeUc();
        var processId = DbFixture.StartProcess();
        var workerId = DbFixture.StartWorker();
        Assert.NotNull(workerId);
        var operationId = DbFixture.NextOperationToRun();
        DbFixture.SetScriptCode(operationId, $"THROW 50001, 'A test error message.', 1;");

        // Act
        DbFixture.RunOperation(operationId, (int)workerId);

        // Assert
        var logEntries = DbFixture.GetErrorLogSince(startTime);
        Assert.NotNull(logEntries);
        Assert.Single(logEntries);
        var entry = logEntries.First();
        Assert.Equivalent(
            new { OperationId = operationId, WorkerId = workerId, ProcessId = processId },
            new { entry.OperationId, entry.WorkerId, entry.ProcessId });
    }
}