namespace Vixan.Db.Test.Models;

public class Thread
{
    public int ThreadId { get; set; }

    public DateTime StartTime { get; set; }

    public DateTime? CompleteTime { get; set; }

    public required string Status { get; set; }

    public int ProcessId { get; set; }
}