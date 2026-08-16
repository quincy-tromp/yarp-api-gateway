using System.Text;
using System.Text.Json;
using System.Text.Json.Nodes;
using Yarp.Gateway;
using Yarp.ReverseProxy.Transforms;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddReverseProxy()
    .LoadFromConfig(builder.Configuration.GetSection("ReverseProxy"))
    .DoCustomResponseTransformation();

var app = builder.Build();

app.MapReverseProxy();

await app.RunAsync();
