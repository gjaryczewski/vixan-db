using Vixan.Db.Test.Fixtures;

namespace Vixan.Db.Test.ProcedureTests;

[Collection("Sequential")]
public class StartWorkerTest
{
    [Fact]
    public void StartWorker_Breaks_When_No_Process_Is_Started()
    {
        // Arrange
        DbFixture.Reset();
        Assert.Null(DbFixture.GetCurrentProcess());
        var workersBefore = DbFixture.GetCurrentWorkers(); 
        Assert.NotNull(workersBefore);
        Assert.Empty(workersBefore);
        var startTime = DbFixture.GetTimeUc();
    
        // Act
        var workerId = DbFixture.StartWorker();

        // Assert
        Assert.Null(workerId);
        var logEntries = DbFixture.GetErrorLog(startTime);
        Assert.NotNull(logEntries);
        Assert.Single(logEntries);
        var entry = logEntries.First();
        Assert.Equivalent(
            new { ProcedureName = "dbo.StartWorker" },
            new { entry.ProcedureName });
        var workersAfter = DbFixture.GetCurrentWorkers(); 
        Assert.NotNull(workersAfter);
        Assert.Empty(workersAfter);
    }
    
    [Fact]
    public void StartWorker_Registers_New_Worker_When_Process_Is_Active()
    {
        // Arrange
        DbFixture.Reset();
        DbFixture.StartProcess();
        var process = DbFixture.GetCurrentProcess();
        Assert.NotNull(process);
        Assert.Equal("STARTED", process.Status);
        var workersBefore = DbFixture.GetCurrentWorkers(); 
        Assert.NotNull(workersBefore);
        Assert.Empty(workersBefore);
        var startTime = DbFixture.GetTimeUc();
    
        // Act
        var workerId = DbFixture.StartWorker();

        // Assert
        Assert.NotNull(workerId);
        var logEntries = DbFixture.GetErrorLog(startTime);
        Assert.NotNull(logEntries);
        Assert.Empty(logEntries);
        var workersAfter = DbFixture.GetCurrentWorkers(); 
        Assert.NotNull(workersAfter);
        Assert.Single(workersAfter);
        Assert.Equal(workerId, workersAfter.First().WorkerId);
    }
}