using System;
using System.Collections.Generic;

namespace Dub.Infrastructure.Database.Models
{
    public partial class Process
    {
        public Process()
        {
            StartedProcesses = new HashSet<StartedProcess>();
        }

        public long Id { get; set; }
        public string Name { get; set; }
        public long StartStepId { get; set; }

        public virtual ProcessStep StartStep { get; set; }
        public virtual ICollection<StartedProcess> StartedProcesses { get; set; }
    }
}
