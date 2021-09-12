using Microsoft.EntityFrameworkCore;

namespace Dub.Infrastructure.Database
{
    public class DubContext : DbContext
    {
        public DubContext(DbContextOptions<DubContext> options) :
            base(options) { }
    }
}