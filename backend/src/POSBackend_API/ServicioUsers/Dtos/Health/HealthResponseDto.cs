namespace ServicioUsers.Dtos.Health
{
    public class HealthResponseDto
    {
        public bool Status {get; set;}
        public string? Version {get; set;}
        public DateTime Timestamp {get; set;}
    }
}