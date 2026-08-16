using System.Text;
using System.Text.Json;
using System.Text.Json.Nodes;
using Yarp.ReverseProxy.Transforms;

namespace Yarp.Gateway;

public static class IReverseProxyBuilderExtensions
{
    extension(IReverseProxyBuilder proxyBuilder)
    {
        public IReverseProxyBuilder DoCustomResponseTransformation()
        {
            return proxyBuilder.AddTransforms(async context =>
            {
                context.AddResponseTransform(async responseContext =>
                {
                    var proxyResponse = responseContext.ProxyResponse;
                    if (proxyResponse is null)
                    {
                        return;
                    }

                    var mediaType = proxyResponse.Content.Headers.ContentType?.MediaType;
                    if (mediaType is null || !mediaType.Contains("application/json", StringComparison.OrdinalIgnoreCase))
                    {
                        return;
                    }

                    var originalBytes = await proxyResponse.Content.ReadAsByteArrayAsync();
                    if (originalBytes.Length == 0)
                    {
                        return;
                    }

                    try
                    {
                        var body = Encoding.UTF8.GetString(originalBytes);

                        var node = JsonNode.Parse(body);

                        if (node is not JsonObject obj)
                        {
                            return;
                        }

                        obj["servedBy"] = "gateway";

                        var newBody = obj.ToJsonString();
                        var newBytes = Encoding.UTF8.GetBytes(newBody);

                        responseContext.SuppressResponseBody = true;

                        responseContext.HttpContext.Response.ContentLength = newBytes.Length;

                        await responseContext.HttpContext.Response.Body.WriteAsync(newBytes);
                    }
                    catch (JsonException)
                    {
                        responseContext.SuppressResponseBody = true;

                        responseContext.HttpContext.Response.ContentLength = originalBytes.Length;

                        await responseContext.HttpContext.Response.Body.WriteAsync(originalBytes);
                    }
                });
            });
        }
    }
}
