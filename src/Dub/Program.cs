using System;
using AutoMapper;
using Dub;
using Dub.Grpc;
using Dub.Grpc.Interceptors;
using Dub.Infrastructure;
using Dub.Infrastructure.Database;
using Dub.Infrastructure.Profiles;
using Microsoft.AspNetCore.Builder;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using RunnableProcessesService = DubGrpc.RunnableProcesses.RunnableProcessesService;

var builder = WebApplication.CreateBuilder(args);

if (builder.Environment.IsDevelopment())
{
    builder.Configuration.AddUserSecrets<MainAssembly>(true, true);
}

builder.Services.AddDatabase(builder.Configuration);
builder.Services.AddGrpc(options => options.Interceptors.Add(typeof(GrpcExceptionInterceptor)));
builder.Services.AddAutoMapper(typeof(ProductClassProfile).Assembly);

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.UseDeveloperExceptionPage();
    app.Services.UseDefaultData();
}

app.UseRouting();

app.UseEndpoints(endpoints =>
{
    endpoints.MapGrpcService<RunnableProcessService>();
    endpoints.MapGrpcService<StepResolutionService>();
    endpoints.MapGrpcService<ProcessStepService>();
    endpoints.MapGrpcService<ProductClassService>();
    endpoints.MapGrpcService<ProductService>();
});

app.Run();