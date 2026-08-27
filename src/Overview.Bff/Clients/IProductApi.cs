using Overview.Bff.Models;
using Refit;

namespace Overview.Bff.Clients;

public interface IProductApi
{
    [Get("/products")]
    Task<CollectionResponse<Product>> GetProductsAsync(
        [Header("X-Internal-Gateway_key")] string internalGatewayKey,
        [Query(CollectionFormat.Csv)] IEnumerable<int> productIds);
}
