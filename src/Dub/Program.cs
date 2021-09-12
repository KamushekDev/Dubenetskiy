using System;
using Dub;
using Dub.Infrastructure.Database;
using Microsoft.AspNetCore.Builder;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Hosting;

var builder = WebApplication.CreateBuilder(args);

if (builder.Environment.IsDevelopment())
{
    builder.Configuration.AddUserSecrets<MainAssembly>(true, true);
}

builder.Services.AddDatabase(builder.Configuration);

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.UseDeveloperExceptionPage();
    app.Services.AddDefaultData();
}

app.MapGet("/", (Func<string>)(() => "Hello World!"));

app.Run();