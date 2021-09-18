using System;
using Dub;
using Dub.Grpc;
using Dub.Infrastructure;
using Dub.Infrastructure.Database;
using Microsoft.AspNetCore.Builder;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;

var builder = WebApplication.CreateBuilder(args);

if (builder.Environment.IsDevelopment())
{
    builder.Configuration.AddUserSecrets<MainAssembly>(true, true);
}

builder.Services.AddDatabase(builder.Configuration);
builder.Services.AddGrpc();
builder.Services.AddAutoMapper(typeof(AutoMapperProfile).Assembly);

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.UseDeveloperExceptionPage();
    app.Services.UseDefaultData();
}

app.UseRouting();

app.UseEndpoints(endpoints => { endpoints.MapGrpcService<DubService>(); });

app.Run();