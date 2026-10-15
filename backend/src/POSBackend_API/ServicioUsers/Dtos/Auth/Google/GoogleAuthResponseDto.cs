namespace ServicioUsers.Dtos.Auth.Google
{
    public class GoogleAuthResponseDto
    {
        public bool Success { get; set; }
        public string Message { get; set; } = string.Empty;
    }
}