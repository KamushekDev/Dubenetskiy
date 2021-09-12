using System;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Options;

namespace Dub.Infrastructure.Database
{
    public static class ServiceCollectionExtensions
    {
        public static void AddDatabase(this IServiceCollection sc, IConfiguration configuration)
        {
            sc.AddOptions<PostgresOptions>()
                .Bind(configuration.GetSection(PostgresOptions.OptionName))
                .ValidateDataAnnotations();

            sc.AddDbContext<DubContext>((sp, options) =>
            {
                var dbOptions = sp.GetService<IOptions<PostgresOptions>>();
                var connectionString = dbOptions!.Value.CombineToConnectionString;
                options.UseNpgsql(connectionString);
            });
        }


        public static void AddDefaultData(this IServiceProvider sp)
        {
            var scope = sp.CreateScope();
            var context = scope.ServiceProvider.GetRequiredService<DubContext>();


            scope.Dispose();
        }
    }
}