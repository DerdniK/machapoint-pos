namespace ServicioUsers.Dtos
{
    public class LoginResponseDto
    {
        public bool Success {get; set;} 
        public string? Message {get; set;}
        public AuthResponseDto? AuthData {get; set;}
    }
}