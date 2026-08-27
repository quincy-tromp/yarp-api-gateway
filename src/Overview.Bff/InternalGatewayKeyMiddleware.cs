using System.Security.Cryptography;
using System.Text;
using Microsoft.Extensions.Options;

namespace Overview.Bff;

public sealed class InternalGatewayKeyMiddleware(RequestDelegate next,
        IOptions<GatewaySecurityOptions> options)
{
    private const string HeaderName = "X-Internal-Gateway-Key";

    public async Task InvokeAsync(HttpContext context)
    {
        var expectedKey = options.Value.InternalGatewayKey;

        if (string.IsNullOrWhiteSpace(expectedKey))
        {
            throw new InvalidOperationException(
                "InternalGatewayKey is not configured.");
        }

        if (!context.Request.Headers.TryGetValue(
                HeaderName,
                out var providedKey))
        {
            context.Response.StatusCode = StatusCodes.Status403Forbidden;
            return;
        }

        if (!CryptographicOperations.FixedTimeEquals(
                Encoding.UTF8.GetBytes(providedKey.ToString()),
                Encoding.UTF8.GetBytes(expectedKey)))
        {
            context.Response.StatusCode = StatusCodes.Status403Forbidden;
            return;
        }

        await next(context);
    }
}

public sealed class GatewaySecurityOptions
{
    public string InternalGatewayKey { get; set; } = string.Empty;
}

