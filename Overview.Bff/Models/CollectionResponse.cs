namespace Overview.Bff.Models;

public sealed class CollectionResponse<T>
{
    public required IEnumerable<T> Items { get; set; }
}
