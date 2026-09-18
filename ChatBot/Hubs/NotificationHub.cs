using Microsoft.AspNetCore.SignalR;
using DataAccessLayer;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;

namespace ChatBot.Hubs
{
    public class NotificationHub : Hub
    {
        private readonly AppDbContext _context;

        public NotificationHub(AppDbContext context)
        {
            _context = context;
        }

        public async Task JoinGroup(string groupName)
        {
            await Groups.AddToGroupAsync(Context.ConnectionId, groupName);
        }

      
    }
}
