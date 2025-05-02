namespace Vixan.Db.Test.Models;

public class Worker
{
    public int WorkerId { get; set; }

    public DateTime StartTime { get; set; }

    public DateTime? StopTime { get; set; }

    public required string Status { get; set; }

    public int ProcessId { get; set; }
}