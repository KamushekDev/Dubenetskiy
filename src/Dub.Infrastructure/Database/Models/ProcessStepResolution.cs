using System;
using System.Collections.Generic;

namespace Dub.Infrastructure.Database.Models
{
    public partial class ProcessStepResolution
    {
        public long CurrentStepId { get; set; }
        public long NextStepId { get; set; }
        public string ResolutionText { get; set; }
        public long Id { get; set; }

        public virtual ProcessStep CurrentStep { get; set; }
        public virtual ProcessStep NextStep { get; set; }
    }
}
