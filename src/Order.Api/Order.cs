namespace Orders.Api;

public sealed class Order
{
    public int Id { get; set; }

    public string CustomerName { get; set; } = string.Empty;

    public List<OrderItem> Items { get; set; } = [];

    public decimal Total { get; set; }

    public string Status { get; set; } = string.Empty;
}

public sealed class OrderItem
{
    public int ProductId { get; set; }

    public int Quantity { get; set; }

    public decimal UnitPrice { get; set; }
}
