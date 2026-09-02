namespace ServicioUsers.Dtos.Auth.Register
{
    public class RegisterRequestDto
    {
        public string Username { get; set; }
        public string Password { get; set; }
        public string Firstname { get; set; }
        public string Lastname { get; set; }
        public int Roleid { get; set; }
    }
}