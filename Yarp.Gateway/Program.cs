using System.Text;
using System.Text.Json;
using System.Text.Json.Nodes;
using Yarp.Gateway;
using Yarp.ReverseProxy.Transforms;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddHealthChecks();

builder.Services.AddReverseProxy()
    .LoadFromConfig(builder.Configuration.GetSection("ReverseProxy"))
    .DoCustomResponseTransformation();

builder.Services.AddCors(options =>
{
    options.AddPolicy("ReadOnly", policy =>
    {
        policy.WithMethods("GET");
    });
});

var app = builder.Build();

app.MapReverseProxy();

app.MapHealthChecks("/api/health");

app.UseCors("ReadOnly");

await app.RunAsync();
