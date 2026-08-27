using Azure.Monitor.OpenTelemetry.AspNetCore;
using Bogus;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.Identity.Web;
using Products.Api;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddHealthChecks();

builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddMicrosoftIdentityWebApi(builder.Configuration.GetSection("AzureAd"));

builder.Services.AddAuthorization();

builder.Services.AddOpenTelemetry()
    .UseAzureMonitor();

builder.Services.Configure<GatewaySecurityOptions>(
    builder.Configuration.GetSection("GatewaySecurity"));

var app = builder.Build();

app.UseHttpsRedirection();

app.UseAuthentication();
app.UseAuthorization();

app.UseMiddleware<InternalGatewayKeyMiddleware>();

var products = new Faker<Product>()
    .RuleFor(p => p.Id, f => f.IndexFaker + 1)
    .RuleFor(p => p.Name, f => f.Commerce.ProductName())
    .RuleFor(p => p.Category, f => f.Commerce.Categories(1).Single())
    .RuleFor(p => p.Price, f => decimal.Parse(f.Commerce.Price(10, 500)))
    .RuleFor(p => p.Stock, f => f.Random.Int(0, 100))
    .Generate(20);

app.MapGet("/products", (string? ids) =>
{
    if (string.IsNullOrEmpty(ids))
    {
        return Results.Ok(new { Items = products });
    }
    
    var productIds = ids
        .Split(',', StringSplitOptions.RemoveEmptyEntries)
        .Select(id => int.TryParse(id, out var value) ? value : (int?)value)
        .Where(id => id.HasValue)
        .Select(id => id!.Value)
        .ToList();

    var results = products
        .Where(p => productIds.Contains(p.Id))
        .ToList();

    return Results.Ok(new { Items = results });
}).RequireAuthorization()
.RequireScope("Products.Read");

app.MapHealthChecks("/health");

await app.RunAsync();
