using Azure.Monitor.OpenTelemetry.AspNetCore;
using Bogus;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.Identity.Web;
using Orders.Api;

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

var orderFaker = new Faker<Order>()
    .RuleFor(o => o.Id, f => f.IndexFaker + 1)
    .RuleFor(o => o.CustomerName, f => f.Name.FullName())
    .RuleFor(o => o.Status, f => f.PickRandom(
        "Pending",
        "Processing",
        "Completed",
        "Cancelled"
    ))
    .RuleFor(o => o.Items, f =>
    {
        var itemCount = f.Random.Int(1, 4);

        return new Faker<OrderItem>()
            .RuleFor(i => i.ProductId, f => f.Random.Int(1, 20))
            .RuleFor(i => i.Quantity, f => f.Random.Int(1, 5))
            .RuleFor(i => i.UnitPrice, f =>
                decimal.Parse(f.Commerce.Price(10, 500)))
            .Generate(itemCount);
    })
    .RuleFor(o => o.Total, (f, order) =>
        order.Items.Sum(i => i.Quantity * i.UnitPrice));

var orders = orderFaker.Generate(20);

app.MapGet("/orders", () =>
{
    return Results.Ok(new { Items = orders });
}).RequireAuthorization()
.RequireScope("Orders.Read");

app.MapHealthChecks("/health");

await app.RunAsync();
