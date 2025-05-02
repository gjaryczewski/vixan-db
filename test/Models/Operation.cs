namespace Vixan.Db.Test.Models;

public class Operation
{
    public int OperationId { get; set; }

    public required string ScriptName { get; set; }

    public DateTime StartTime { get; set; }

    public DateTime? CompleteTime { get; set; }

    public required string Status { get; set; }

    public int WorkerId { get; set; }

    public int ProcessId { get; set; }

    public int SessionId { get; set; }
}