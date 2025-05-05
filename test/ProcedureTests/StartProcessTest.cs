using Vixan.Db.Test.Fixtures;

namespace Vixan.Db.Test.ProcedureTests;

[Collection("Sequential")]
public class StartProcessTest : BaseProcedureTest
{
    [Fact]
    public void StartProcess_Breaks_When_Another_Process_Already_Started()
    {
        // Arrange
        DbFixture.Reset();
        _ = DbFixture.StartProcess();
        var startTime = DbFixture.GetTimeUc();

        // Act
        var processId = DbFixture.StartProcess();

        // Assert
        Assert.Null(processId);
        AssertSingleErrorSince(startTime, "dbo.StartProcess", "Another process is already started.");
    }

    [Fact]
    public void StartProcess_Plans_Operations_When_Starting()
    {
        // Arrange
        DbFixture.Reset();
        AssertNoCurrentProcess();
        var startTime = DbFixture.GetTimeUc();

        // Act
        var processId = DbFixture.StartProcess();

        // Assert
        Assert.NotNull(processId);
        AssertNoErrorSince(startTime);
        var process = DbFixture.GetCurrentProcess();
        Assert.NotNull(process);
        Assert.Equal("STARTED", process.Status);
        var currentOperations = DbFixture.GetCurrentOperations();
        Assert.NotNull(currentOperations);
        Assert.NotEmpty(currentOperations);
        Assert.All(currentOperations, o => Assert.Equal("PLANNED", o.Status));
    }
}