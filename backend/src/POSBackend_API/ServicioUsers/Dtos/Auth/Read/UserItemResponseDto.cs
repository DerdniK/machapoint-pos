using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace ServicioUsers.Dtos.Auth.Read
{
    public class UserItemResponseDto
    {
        public Guid UserId { get; set; }
        public string? Username { get; set; } = string.Empty;
        public string? FirstName { get; set; } = string.Empty;
        public string? LastName { get; set; } = string.Empty;
        public int? RoleId { get; set; }
        public DateTime? CreatedAt { get; set; }
    }
}