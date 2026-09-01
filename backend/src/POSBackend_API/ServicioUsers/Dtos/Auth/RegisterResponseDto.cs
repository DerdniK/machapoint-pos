using ServicioUsers.Dtos.Auth;

namespace ServicioUsers.Dtos.Auth
{
    public class RegisterResponseDto
    {
        public bool Success {get; set;} 
        public string? Message {get; set;}
        public string Username { get; set; }
        public int Roleid { get; set; }
        public DateTime created_at {get;set;}
    }
}