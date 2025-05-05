namespace Vixan.Db.Test.Models;

public class ProcessLogEntry
{
    public int ProcessLogId { get; set; }

    public DateTime LogTime { get; set; }

    public int ProcessId { get; set; }

    public required string Status { get; set; }

    public required string UserLogin { get; set; }

    public required string UserHost { get; set; }
}