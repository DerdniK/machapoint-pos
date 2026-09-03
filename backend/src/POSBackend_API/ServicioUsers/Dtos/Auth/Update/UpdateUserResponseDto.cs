namespace ServicioUsers.Dtos.Auth.Update
{
    public class UpdateUserResponseDto
    {
        public bool Success {get; set;}
        public string Message {get; set;}
        public string Username {get; set;} = "No modificado";
        public string Password {get; set;} = "No modificado";
        public string Firstname {get; set;} = "No modificado";
        public string Lastname {get; set;} = "No modificado";
        public int Roleid {get; set;} = 00000;
    }
}