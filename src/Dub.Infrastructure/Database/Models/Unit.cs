using System;
using System.Collections.Generic;

namespace Dub.Infrastructure.Database.Models
{
    public partial class Unit
    {
        public Unit()
        {
            Parameters = new HashSet<Parameter>();
        }

        public long Id { get; set; }
        public string Name { get; set; }

        public virtual ICollection<Parameter> Parameters { get; set; }
    }
}
