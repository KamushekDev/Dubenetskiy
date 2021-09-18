using System;
using System.Collections.Generic;

namespace Dub.Infrastructure.Database.Models
{
    public partial class ProductClass
    {
        public ProductClass()
        {
            Products = new HashSet<Product>();
        }

        public long Id { get; set; }
        public string Name { get; set; }
        public long? ParentId { get; set; }

        public virtual ICollection<Product> Products { get; set; }
    }
}
