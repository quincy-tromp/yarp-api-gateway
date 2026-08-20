namespace Products.Api;

public sealed class Product
{
    public int Id { get; set; }
    public string Name { get; set; } = default!;
    public string Category { get; set; } = default!;
    public decimal Price { get; set; }
    public int Stock { get; set; }
}
