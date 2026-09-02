namespace ServicioUsers.Dtos.Auth.Delete
{
    public class DeleteUserResponseDto
    {
        public Guid Deletedid {get; set;}
        public string Message {get; set;}
        public bool Status {get; set;}
    }
}