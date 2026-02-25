using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using Azure.Identity;

namespace ZavaStorefront.Services
{
    public class ChatService
    {
        private readonly HttpClient _httpClient;
        private readonly IConfiguration _configuration;
        private readonly ILogger<ChatService> _logger;
        private readonly DefaultAzureCredential _credential;

        public ChatService(HttpClient httpClient, IConfiguration configuration, ILogger<ChatService> logger)
        {
            _httpClient = httpClient;
            _configuration = configuration;
            _logger = logger;
            _credential = new DefaultAzureCredential();
        }

        public async Task<string> SendMessageAsync(string userMessage)
        {
            var endpoint = _configuration["AzureAI:Endpoint"]
                ?? throw new InvalidOperationException("AzureAI:Endpoint is not configured.");
            var deploymentName = _configuration["AzureAI:DeploymentName"] ?? "Phi-4";

            var requestUri = $"{endpoint.TrimEnd('/')}/openai/deployments/{deploymentName}/chat/completions?api-version=2024-12-01-preview";

            var requestBody = new
            {
                messages = new[]
                {
                    new { role = "system", content = "You are a helpful assistant for the Zava Storefront." },
                    new { role = "user", content = userMessage }
                },
                max_tokens = 800,
                temperature = 0.7
            };

            var json = JsonSerializer.Serialize(requestBody);
            var content = new StringContent(json, Encoding.UTF8, "application/json");

            try
            {
                // Get Azure AD token for Cognitive Services
                var tokenResult = await _credential.GetTokenAsync(
                    new Azure.Core.TokenRequestContext(new[] { "https://cognitiveservices.azure.com/.default" }));

                using var request = new HttpRequestMessage(HttpMethod.Post, requestUri);
                request.Content = content;
                request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", tokenResult.Token);

                _logger.LogInformation("Sending chat request to AI endpoint using Entra ID auth");
                var stopwatch = System.Diagnostics.Stopwatch.StartNew();
                var response = await _httpClient.SendAsync(request);
                stopwatch.Stop();

                if (stopwatch.ElapsedMilliseconds > 5000)
                {
                    _logger.LogWarning("Chat API latency exceeded threshold: {ElapsedMs}ms", stopwatch.ElapsedMilliseconds);
                }

                if ((int)response.StatusCode == 429)
                {
                    var retryAfter = response.Headers.RetryAfter?.Delta?.TotalSeconds ?? 10;
                    _logger.LogWarning("Rate limited by AI endpoint. Retry after {RetryAfter}s", retryAfter);
                    return $"The AI service is currently busy. Please try again in {retryAfter} seconds.";
                }

                if (!response.IsSuccessStatusCode)
                {
                    var errorBody = await response.Content.ReadAsStringAsync();
                    _logger.LogError("Chat API returned {StatusCode}: {Error}", response.StatusCode, errorBody);
                    return $"Error: The AI service returned status {(int)response.StatusCode}. Please try again later.";
                }

                var responseJson = await response.Content.ReadAsStringAsync();
                using var doc = JsonDocument.Parse(responseJson);
                var reply = doc.RootElement
                    .GetProperty("choices")[0]
                    .GetProperty("message")
                    .GetProperty("content")
                    .GetString();

                return reply ?? "No response received.";
            }
            catch (TaskCanceledException)
            {
                _logger.LogError("Chat API request timed out");
                return "Error: The request timed out. Please try again.";
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error calling chat API");
                return $"Error: Unable to reach the AI service. Please try again later.";
            }
        }
    }
}
