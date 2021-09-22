using System;
using System.Collections.Generic;

namespace Dub.Infrastructure.Database.Models
{
    public partial class ProcessStep
    {
        public ProcessStep()
        {
            ProcessStepResolutionCurrentSteps = new HashSet<ProcessStepResolution>();
            ProcessStepResolutionNextSteps = new HashSet<ProcessStepResolution>();
            RunnableProcesses = new HashSet<RunnableProcess>();
        }

        public long Id { get; set; }
        public string Name { get; set; }

        public virtual ICollection<ProcessStepResolution> ProcessStepResolutionCurrentSteps { get; set; }
        public virtual ICollection<ProcessStepResolution> ProcessStepResolutionNextSteps { get; set; }
        public virtual ICollection<RunnableProcess> RunnableProcesses { get; set; }
    }
}
