namespace Vixan.Db.Test.Models;

public class ThreadLogEntry
{
    public int ThreadLogId { get; set; }
    
    public DateTime LogTime { get; set; }

    public int ThreadId { get; set; }

    public required string Status { get; set; }

    public required string UserLogin { get; set; }

    public required string UserHost { get; set; }
}