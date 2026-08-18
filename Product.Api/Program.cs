using Bogus;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.Identity.Web;
using Products.Api;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddHealthChecks();

builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddMicrosoftIdentityWebApi(builder.Configuration.GetSection("AzureAd"));

builder.Services.AddAuthorization();

var app = builder.Build();

app.UseHttpsRedirection();

app.UseAuthentication();
app.UseAuthorization();

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
}).RequireScope("Products.Read");

app.MapGet("/products/{id:int}", (int id) =>
{
    var product = products.FirstOrDefault(p => p.Id == id);

    return product is null
        ? Results.NotFound(new
        {
            message = $"Product with id {id} was not found."
        })
        : Results.Ok(product);
}).RequireScope("Products.Read");

app.MapHealthChecks("/health");

await app.RunAsync();
