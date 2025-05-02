namespace Vixan.Db.Test.Models;

public class Process
{
    public int ProcessId { get; set; }

    public DateTime StartTime { get; set; }

    public DateTime? CompleteTime { get; set; }

    public required string Status { get; set; }
}