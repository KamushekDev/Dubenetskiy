using System;
using System.Collections.Generic;

namespace Dub.Infrastructure.Database.Models
{
    public partial class StartedProcess
    {
        public long Id { get; set; }
        public long ProcessId { get; set; }
        public DateTime CreatedAt { get; set; }
        public long? CurrentStepId { get; set; }

        public virtual RunnableProcess Process { get; set; }
    }
}
