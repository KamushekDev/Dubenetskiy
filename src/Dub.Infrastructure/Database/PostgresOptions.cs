using System.ComponentModel.DataAnnotations;

namespace Dub.Infrastructure.Database
{
    public class PostgresOptions
    {
        public static string OptionName = "PostgresOptions";

        [Required]
        public string ConnectionString { get; set; }

        [Required]
        public string Username { get; set; }

        [Required]
        public string Password { get; set; }

        public string CombineToConnectionString => $"{ConnectionString};Username={Username};Password={Password}";
    }
}