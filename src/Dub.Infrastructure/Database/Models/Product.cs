using System;
using System.Collections.Generic;

namespace Dub.Infrastructure.Database.Models
{
    public partial class Product
    {
        public Product()
        {
            ProductParameters = new HashSet<ProductParameter>();
        }

        public long Id { get; set; }
        public string Name { get; set; }
        public long ClassId { get; set; }
        public long? BaseId { get; set; }
        public string Version { get; set; }

        public virtual ProductClass Class { get; set; }
        public virtual ICollection<ProductParameter> ProductParameters { get; set; }
    }
}
