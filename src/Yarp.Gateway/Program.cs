using System.Text;
using System.Text.Json;
using System.Text.Json.Nodes;
using Azure.Monitor.OpenTelemetry.AspNetCore;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using Yarp.Gateway;
using Yarp.ReverseProxy.Transforms;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddHealthChecks();

builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        var jwt = builder.Configuration.GetSection("Jwt");

        options.Authority = jwt.GetValue<string>("Authority");
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidIssuer = jwt.GetValue<string>("Issuer"),
            ValidateAudience = true,
            ValidAudiences = jwt.GetSection("Audiences").Get<string[]>(),
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
        };
    });

builder.Services.AddAuthorizationBuilder()
    .AddPolicy("Products.Api.Access", policy =>
    {
        policy.RequireAuthenticatedUser();
        policy.RequireClaim("http://schemas.microsoft.com/identity/claims/scope", "Products.Read");
    })
    .AddPolicy("Orders.Api.Access", policy =>
    {
        policy.RequireAuthenticatedUser();
        policy.RequireClaim("http://schemas.microsoft.com/identity/claims/scope", "Orders.Read");
    })
    .AddPolicy("Overview.Bff.Access", policy =>
    {
        policy.RequireAuthenticatedUser();
        policy.RequireClaim("http://schemas.microsoft.com/identity/claims/scope", "Overview.Read");
    });

builder.Services.AddReverseProxy()
    .LoadFromConfig(builder.Configuration.GetSection("ReverseProxy"))
    .DoCustomResponseTransformation();

builder.Services.AddRequestTimeouts();

builder.Services.AddCors(options =>
{
    options.AddPolicy("ReadOnly", policy =>
    {
        policy.WithMethods("GET");
    });
});

builder.Services.AddOpenTelemetry()   
    .UseAzureMonitor()
    .WithTracing(tracing =>
    {
        tracing.AddSource("Yarp.ReverseProxy");
    });

var app = builder.Build();

app.UseAuthentication();
app.UseAuthorization();

app.UseRequestTimeouts();

app.MapReverseProxy();

app.MapHealthChecks("/api/health");

app.UseCors("ReadOnly");

await app.RunAsync();
