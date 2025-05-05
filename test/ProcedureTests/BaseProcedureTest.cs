using Vixan.Db.Test.Fixtures;

namespace Vixan.Db.Test.ProcedureTests;

public abstract class BaseProcedureTest
{
    public static void AssertNoErrorSince(DateTime startTime)
    {
        var logEntries = DbFixture.GetErrorLogSince(startTime);
        Assert.NotNull(logEntries);
        Assert.Empty(logEntries);
    }

    public static void AssertSingleErrorSince(DateTime startTime, string procedureName, string errorMessage)
    {
        var logEntries = DbFixture.GetErrorLogSince(startTime);
        Assert.NotNull(logEntries);
        Assert.Single(logEntries);
        var entry = logEntries.First();
        Assert.Equivalent(
            new { ProcedureName = procedureName, ErrorMessage = errorMessage },
            new { entry.ProcedureName, entry.ErrorMessage });
    }

    public static void AssertNoCurrentProcess()
    {
        Assert.Null(DbFixture.GetCurrentProcess());
    }

    public static void AssertProcessStarted()
    {
        Assert.Null(DbFixture.GetCurrentProcess());
        DbFixture.StartProcess();
        var process = DbFixture.GetCurrentProcess();
        Assert.NotNull(process);
        Assert.Equal("STARTED", process.Status);
    }

    public static void AssertNoCurrentWorkers()
    {
        var currentWorkers = DbFixture.GetCurrentWorkers();
        Assert.NotNull(currentWorkers);
        Assert.Empty(currentWorkers);
    }

    public static void AssertWorkerStarted()
    {
        Assert.NotNull(DbFixture.GetCurrentProcess());
        var workerId = DbFixture.StartWorker();
        Assert.NotNull(workerId);
        AssertWorkerStarted((int)workerId);
    }

    public static void AssertWorkerStarted(int workerId)
    {
        Assert.NotNull(DbFixture.GetCurrentProcess());
        var worker = DbFixture.GetWorkers()?.FirstOrDefault(w => w.WorkerId == workerId);
        Assert.NotNull(worker);
        Assert.Equal("STARTED", worker.Status);
    }

    public static void AssertWorkerStartedThenStopped()
    {
        Assert.NotNull(DbFixture.GetCurrentProcess());
        var workerId = DbFixture.StartWorker();
        Assert.NotNull(workerId);
        DbFixture.StopWorker((int)workerId);
        var worker = DbFixture.GetWorkers()?.FirstOrDefault(w => w.WorkerId == workerId);
        Assert.NotNull(worker);
        Assert.Equal("STOPPED", worker.Status);
    }

    public static void AssertWorkerStopped(int workerId)
    {
        Assert.NotNull(DbFixture.GetCurrentProcess());
        var worker = DbFixture.GetWorkers()?.FirstOrDefault(w => w.WorkerId == workerId);
        Assert.NotNull(worker);
        Assert.Equal("STOPPED", worker.Status);
    }

    public static void AssertNoCurrentOperation()
    {
        var currentOperations = DbFixture.GetCurrentOperations();
        Assert.NotNull(currentOperations);
        Assert.Empty(currentOperations);
    }

    public static void AssertNoOperationStarted()
    {
        Assert.NotNull(DbFixture.GetCurrentProcess());
        var currentOperations = DbFixture.GetCurrentOperations();
        Assert.NotNull(currentOperations);
        Assert.NotEmpty(currentOperations);
        var startedOperations = currentOperations.Where(o => o.Status == "STARTED");
        Assert.Empty(startedOperations);
    }

    public static void AssertStartedOperation(int operationId)
    {
        Assert.NotNull(DbFixture.GetCurrentProcess());
        var currentOperations = DbFixture.GetCurrentOperations();
        Assert.NotNull(currentOperations);
        Assert.NotEmpty(currentOperations);
        var startedOperations = currentOperations.Where(o => o.Status == "STARTED");
        Assert.Empty(startedOperations);
    }

    public static void AssertOperationCompleted(int operationId, int maxDurationInSec = 10)
    {
        AssertWorkerStarted();
        var workerId = DbFixture.GetFirstCurrentWorker().WorkerId;
        DbFixture.RunOperation(operationId, (int)workerId);
        var durationInSec = 0;
        var status = string.Empty;
        while (durationInSec < maxDurationInSec)
        {
            status = DbFixture.GetOperation(operationId)!.Status;
            if (status == "COMPLETED") break;

            Task.Delay(TimeSpan.FromSeconds(1));
            durationInSec++;
        }
        Assert.Equal("COMPLETED", status);
    }

    public static void AssertOperationTerminated(int operationId)
    {
        DbFixture.TerminateOperation(operationId);
        Assert.Equal("TERMINATED", DbFixture.GetOperation(operationId)!.Status);
    }
}