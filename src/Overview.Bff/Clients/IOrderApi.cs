using Overview.Bff.Models;
using Refit;

namespace Overview.Bff.Clients;

public interface IOrderApi
{
    [Get("/orders")]
    Task<CollectionResponse<Order>> GetOrdersAsync();
}
