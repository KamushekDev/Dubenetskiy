using System;
using System.Collections.Generic;

namespace Dub.Infrastructure.Database.Models
{
    public partial class ProductParameter
    {
        public long ProductId { get; set; }
        public long ParameterId { get; set; }

        public virtual Parameter Parameter { get; set; }
        public virtual Product Product { get; set; }
    }
}
