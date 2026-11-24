using System.Net.Http.Headers;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using Microsoft.AspNetCore.WebUtilities;

namespace WebApi.Services;

public class SocialLogin
{
    public static readonly string[] Providers = ["google", "facebook", "zalo"];

    private readonly IConfiguration configuration;
    private readonly HttpClient client;
    private readonly ILogger<SocialLogin> logger;

    public SocialLogin(IConfiguration configuration, IHttpClientFactory factory, ILogger<SocialLogin> logger)
    {
        this.configuration = configuration;
        client = factory.CreateClient("external");
        this.logger = logger;
    }

    private string? Option(string provider, string name) => configuration[$"Social:{provider}:{name}"];

    public bool IsEnabled(string provider) => Providers.Contains(provider) &&
        !string.IsNullOrWhiteSpace(Option(provider, "ClientId")) &&
        !string.IsNullOrWhiteSpace(Option(provider, "ClientSecret")) &&
        Uri.TryCreate(Option(provider, "Callback"), UriKind.Absolute, out var uri) &&
        (uri.Scheme == "https" || (uri.IsLoopback && provider == "google"));

    private string FacebookVersion => configuration["Social:facebook:Version"] ?? "v27.0";

    public string GetAuthorizationUrl(string provider, string state, string verifier)
    {
        var query = new Dictionary<string, string?>
        {
            ["state"] = state,
            ["redirect_uri"] = Option(provider, "Callback")
        };
        query[provider == "zalo" ? "app_id" : "client_id"] = Option(provider, "ClientId");
        if (provider != "zalo") query["response_type"] = "code";

        string url;
        switch (provider)
        {
            case "google":
                url = "https://accounts.google.com/o/oauth2/v2/auth";
                query["scope"] = "openid profile";
                query["code_challenge_method"] = "S256";
                break;
            case "facebook":
                url = $"https://www.facebook.com/{FacebookVersion}/dialog/oauth";
                query["scope"] = "public_profile";
                break;
            default:
                url = "https://oauth.zaloapp.com/v4/permission";
                break;
        }

        if (provider != "facebook")
            query["code_challenge"] = WebEncoders.Base64UrlEncode(SHA256.HashData(Encoding.ASCII.GetBytes(verifier)));
        return QueryHelpers.AddQueryString(url, query);
    }

    public async Task<(string Id, string Name)> GetProfile(string provider, string code, string verifier)
    {
        var fields = new Dictionary<string, string>
        {
            ["code"] = code, ["grant_type"] = "authorization_code"
        };
        HttpRequestMessage request;
        if (provider == "zalo")
        {
            fields["app_id"] = Option(provider, "ClientId")!;
            fields["code_verifier"] = verifier;
            request = new HttpRequestMessage(HttpMethod.Post, "https://oauth.zaloapp.com/v4/access_token")
            {
                Content = new FormUrlEncodedContent(fields)
            };
            request.Headers.Add("secret_key", Option(provider, "ClientSecret"));
        }
        else
        {
            fields["client_id"] = Option(provider, "ClientId")!;
            fields["client_secret"] = Option(provider, "ClientSecret")!;
            fields["redirect_uri"] = Option(provider, "Callback")!;
            if (provider == "google")
            {
                fields["code_verifier"] = verifier;
                request = new HttpRequestMessage(HttpMethod.Post, "https://oauth2.googleapis.com/token")
                {
                    Content = new FormUrlEncodedContent(fields)
                };
            }
            else
            {
                fields.Remove("grant_type");
                string url = $"https://graph.facebook.com/{FacebookVersion}/oauth/access_token";
                request = new HttpRequestMessage(HttpMethod.Get, QueryHelpers.AddQueryString(
                    url, fields.ToDictionary(p => p.Key, p => (string?)p.Value)));
            }
        }

        using (request)
        using (var response = await client.SendAsync(request))
        {
            using var token = await ReadProviderJson(provider, "token exchange", response);
            string accessToken = token.RootElement.GetProperty("access_token").GetString()!;
            using var profile = new HttpRequestMessage(HttpMethod.Get, provider switch
            {
                "google" => "https://openidconnect.googleapis.com/v1/userinfo",
                "facebook" => FacebookProfileUrl(accessToken),
                _ => "https://graph.zalo.me/v2.0/me?fields=id,name"
            });
            if (provider == "zalo") profile.Headers.Add("access_token", accessToken);
            else profile.Headers.Authorization = new AuthenticationHeaderValue("Bearer", accessToken);
            using var result = await client.SendAsync(profile);
            using var json = await ReadProviderJson(provider, "profile lookup", result);
            var element = json.RootElement;
            string id = element.GetProperty(provider == "google" ? "sub" : "id").GetString()!;
            string name = element.TryGetProperty("name", out var field) ? field.GetString() ?? provider : provider;
            return (id, name);
        }
    }

    private string FacebookProfileUrl(string accessToken)
    {
        byte[] secret = Encoding.UTF8.GetBytes(Option("facebook", "ClientSecret")!);
        byte[] token = Encoding.UTF8.GetBytes(accessToken);
        string proof = Convert.ToHexString(HMACSHA256.HashData(secret, token)).ToLowerInvariant();
        return QueryHelpers.AddQueryString($"https://graph.facebook.com/{FacebookVersion}/me?fields=id,name",
            "appsecret_proof", proof);
    }

    private async Task<JsonDocument> ReadProviderJson(string provider, string step, HttpResponseMessage response)
    {
        JsonDocument body;
        try
        {
            body = JsonDocument.Parse(await response.Content.ReadAsStringAsync());
        }
        catch (JsonException) when (!response.IsSuccessStatusCode)
        {
            logger.LogWarning("Social login {Provider} failed during {Step} with HTTP {StatusCode}.",
                provider, step, (int)response.StatusCode);
            throw new HttpRequestException("OAuth request failed.", null, response.StatusCode);
        }

        JsonElement error = default;
        bool failed = body.RootElement.ValueKind == JsonValueKind.Object &&
            body.RootElement.TryGetProperty("error", out error) &&
            error.ValueKind is not (JsonValueKind.Null or JsonValueKind.False) && ErrorNumber(error) != 0;
        if (response.IsSuccessStatusCode && !failed) return body;

        int? code = error.ValueKind == JsonValueKind.Object ? ErrorField(error, "code") : ErrorNumber(error);
        int? subcode = ErrorField(error, "error_subcode");
        string? reason = error.ValueKind == JsonValueKind.String ? error.GetString() : null;
        if (reason is not ("invalid_client" or "invalid_grant" or "invalid_request" or "access_denied")) reason = null;
        logger.LogWarning("Social login {Provider} failed during {Step}: HTTP {StatusCode}, code {Code}, subcode {Subcode}, reason {Reason}.",
            provider, step, (int)response.StatusCode, code, subcode, reason);
        body.Dispose();
        throw new HttpRequestException("OAuth request failed.", null, response.StatusCode);
    }

    private static int? ErrorField(JsonElement error, string name) =>
        error.ValueKind == JsonValueKind.Object && error.TryGetProperty(name, out var field) ? ErrorNumber(field) : null;

    private static int? ErrorNumber(JsonElement error) =>
        error.ValueKind == JsonValueKind.Number && error.TryGetInt32(out int value) ? value : null;
}
