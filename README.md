Dub

# Scaffold from database

```
#from src folder
dotnet ef dbcontext scaffold "Host=localhost;Database=dub;Port=5433;Username=postgres;Password=postgres" Npgsql.EntityFrameworkCore.PostgreSQL -c DubContext --context-dir Database -f -o Database/Models --schema public -p Dub.Infrastructure -s Dub 
```

**todo**: понять почему вот так не работает

```
#from startup folder (once)
dotnet user-secrets set "Dub:Scaffold:ConnectionString" "Host=localhost;Database=dub;Port=5433;Username=postgres;Password=postgres"
dotnet ef dbcontext scaffold Name=Dub:Scaffold:ConnectionString Npgsql.EntityFrameworkCore.PostgreSQL -c DubContext --context-dir Database -f -o Database/Models --schema public -p Dub.Infrastructure 
```

# Migrations
            
### Add migration
```
dotnet ef migrations
```
