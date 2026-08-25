using System.Collections.Immutable;
using Azure.Monitor.OpenTelemetry.AspNetCore;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.Identity.Abstractions;
using Microsoft.Identity.Web;
using Overview.Bff.Clients;
using Overview.Bff.Models;
using Refit;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddHealthChecks();

builder.Services.AddRefitClient<IProductApi>()
    .ConfigureHttpClient(c =>
    {
        var apiBaseUrl = builder.Configuration.GetValue(
            "ExternalApis:Products:BaseUrl", "https://localhost:5001");
        c.BaseAddress = new Uri(apiBaseUrl);
    }).AddHttpMessageHandler(sp => new MicrosoftIdentityMessageHandler(
        sp.GetRequiredService<IAuthorizationHeaderProvider>(),
        new MicrosoftIdentityMessageHandlerOptions
        {
            Scopes = builder.Configuration
                .GetSection("ExternalApis:Products:Scopes")
                .Get<string[]>()!
        }));
builder.Services.AddRefitClient<IOrderApi>()
    .ConfigureHttpClient(c =>
    {
        var apiBaseUrl = builder.Configuration.GetValue(
            "ExternalApis:Orders:BaseUrl", "https://localhost:6001");
        c.BaseAddress = new Uri(apiBaseUrl);
    }).AddHttpMessageHandler(sp => new MicrosoftIdentityMessageHandler(
        sp.GetRequiredService<IAuthorizationHeaderProvider>(),
        new MicrosoftIdentityMessageHandlerOptions
        {
            Scopes = builder.Configuration
                .GetSection("ExternalApis:Orders:Scopes")
                .Get<string[]>()!
        }));

builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddMicrosoftIdentityWebApi(builder.Configuration.GetSection("AzureAd"))
    .EnableTokenAcquisitionToCallDownstreamApi()
    .AddInMemoryTokenCaches();

builder.Services.AddAuthorization();

builder.Services.AddOpenTelemetry()
    .UseAzureMonitor();

var app = builder.Build();

app.UseHttpsRedirection();

app.UseAuthentication();
app.UseAuthorization();

app.MapGet("/overview", async (IProductApi productApi, IOrderApi orderApi) =>
{
    var ordersResponse = await orderApi.GetOrdersAsync();
    var orders = ordersResponse.Items;

    var productIds = orders
        .SelectMany(o => o.Items)
        .Select(i => i.ProductId)
        .Distinct()
        .ToList();

    var productsResponse = await productApi.GetProductsAsync(productIds);
    var products = productsResponse.Items;

    var productsById = products.ToImmutableDictionary(p => p.Id);

    var orderSummaries = orders.Select(order =>
    {
        var items = order.Items.Select(item =>
        {
            productsById.TryGetValue(item.ProductId, out var product);

            return new ProductOrderItem
            {
                ProductId = item.ProductId,
                ProductName = product?.Name ?? "Unknown product",
                Category = product?.Category ?? "Unknown",
                Quantity = item.Quantity,
                UnitPrice = item.UnitPrice,
                LineTotal = item.Quantity * item.UnitPrice,
                InStock = product?.Stock > 0
            };
        }).ToList();

        return new OrderSummary
        {
            Id = order.Id,
            CustomerName = order.CustomerName,
            Status = order.Status,
            Total = order.Total,
            Items = items
        };
    }).ToList();

    var result = new ProductOrderOverview
    {
        Orders = orderSummaries,
        TotalOrderValue = orderSummaries.Sum(o => o.Total),
        TotalProducts = orderSummaries
            .SelectMany(o => o.Items)
            .Sum(i => i.Quantity)
    };

    return Results.Ok(result);

}).Produces<ProductOrderOverview>()
    .RequireAuthorization()
    .RequireScope("Overview.Read");

app.MapHealthChecks("/health");

await app.RunAsync();
