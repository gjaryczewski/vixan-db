namespace Vixan.Db.Test.Models;

public class WorkerLogEntry
{
    public int WorkerLogId { get; set; }

    public DateTime LogTime { get; set; }

    public int WorkerId { get; set; }

    public required string Status { get; set; }

    public required string UserLogin { get; set; }

    public required string UserHost { get; set; }
}