using Bogus;
using Orders.Api;

var builder = WebApplication.CreateBuilder(args);

var app = builder.Build();

app.UseHttpsRedirection();

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
            .RuleFor(i => i.ProductName, f => f.Commerce.ProductName())
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
    return Results.Ok(new { orders });
});

app.MapGet("/orders/{id:int}", (int id) =>
{
    var order = orders.FirstOrDefault(o => o.Id == id);

    return order is null
        ? Results.NotFound(new
        {
            message = $"Order with id {id} was not found."
        })
        : Results.Ok(order);
});

await app.RunAsync();
