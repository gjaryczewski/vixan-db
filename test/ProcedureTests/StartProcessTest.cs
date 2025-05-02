using System.Reflection;
using Vixan.Db.Test.Fixtures;
using Xunit.Sdk;

namespace Vixan.Db.Test.ProcedureTests;

[Collection("Sequential")]
public class StartProcessTest
{
    [Fact]
    public void StartProcess_Breaks_When_Another_Process_Is_Already_Started()
    {
        // Arrange
        DbFixture.Reset();
        var startTime = DbFixture.GetTimeUc();
        _ = DbFixture.StartProcess();

        // Act
        var processId = DbFixture.StartProcess();

        // Assert
        Assert.Null(processId);
        var logEntries = DbFixture.GetErrorLog(startTime);
        Assert.NotNull(logEntries);
        Assert.Single(logEntries);
        var entry = logEntries.First();
        Assert.Equivalent(
            new { ProcedureName = "dbo.StartProcess" },
            new { entry.ProcedureName });
    }
    
    [Fact]
    public void StartProcess_Plans_Operations_When_Starting()
    {
        // Arrange
        DbFixture.Reset();
        Assert.Empty(DbFixture.GetCurrentOperations()!);
        var startTime = DbFixture.GetTimeUc();

        // Act
        var processId = DbFixture.StartProcess();

        // Assert
        Assert.NotNull(processId);
        Assert.Empty(DbFixture.GetErrorLog(startTime)!);
        var process = DbFixture.GetCurrentProcess();
        Assert.NotNull(process);
        Assert.Equal("STARTED", process.Status);
        var logEntries = DbFixture.GetProcessLog(startTime);
        Assert.NotNull(logEntries);
        Assert.Equal(2, logEntries.Count);
        Assert.Collection(logEntries,
            entry => Assert.Contains("STARTING", entry.Status),
            entry => Assert.Contains("STARTED", entry.Status));
        var currentOps = DbFixture.GetCurrentOperations();
        Assert.NotNull(currentOps);
        Assert.All(currentOps, o => Assert.Equal("PLANNED", o.Status));
    }
}