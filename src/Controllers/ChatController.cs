using Microsoft.AspNetCore.Mvc;
using ZavaStorefront.Models;
using ZavaStorefront.Services;

namespace ZavaStorefront.Controllers
{
    public class ChatController : Controller
    {
        private readonly ChatService _chatService;
        private readonly ILogger<ChatController> _logger;

        public ChatController(ChatService chatService, ILogger<ChatController> logger)
        {
            _chatService = chatService;
            _logger = logger;
        }

        public IActionResult Index()
        {
            return View(new ChatViewModel());
        }

        [HttpPost]
        public async Task<IActionResult> Send(ChatViewModel model)
        {
            if (string.IsNullOrWhiteSpace(model.UserMessage))
            {
                return View("Index", model);
            }

            _logger.LogInformation("User sent chat message");

            model.Conversation.Add(new ChatMessage { Role = "user", Content = model.UserMessage });

            var reply = await _chatService.SendMessageAsync(model.UserMessage);

            model.Conversation.Add(new ChatMessage { Role = "assistant", Content = reply });

            model.UserMessage = string.Empty;

            return View("Index", model);
        }
    }
}
