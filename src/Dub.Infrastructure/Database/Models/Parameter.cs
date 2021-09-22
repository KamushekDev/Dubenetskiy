using System;
using System.Collections.Generic;

namespace Dub.Infrastructure.Database.Models
{
    public partial class Parameter
    {
        public Parameter()
        {
            ProductParameters = new HashSet<ProductParameter>();
        }

        public long Id { get; set; }
        public string Name { get; set; }
        public long UnitId { get; set; }

        public virtual Unit Unit { get; set; }
        public virtual ICollection<ProductParameter> ProductParameters { get; set; }
    }
}
