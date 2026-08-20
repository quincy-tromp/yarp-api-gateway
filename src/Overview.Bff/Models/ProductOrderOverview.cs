namespace Overview.Bff.Models;

public sealed class ProductOrderOverview
{
    public List<OrderSummary> Orders { get; set; } = [];

    public decimal TotalOrderValue { get; set; }

    public int TotalProducts { get; set; }
}

public sealed class OrderSummary
{
    public int Id { get; set; }

    public string CustomerName { get; set; } = string.Empty;

    public string Status { get; set; } = string.Empty;

    public decimal Total { get; set; }

    public List<ProductOrderItem> Items { get; set; } = [];
}

public sealed class ProductOrderItem
{
    public int ProductId { get; set; }

    public string ProductName { get; set; } = string.Empty;

    public string Category { get; set; } = string.Empty;

    public int Quantity { get; set; }

    public decimal UnitPrice { get; set; }

    public decimal LineTotal { get; set; }

    public bool InStock { get; set; }
}
