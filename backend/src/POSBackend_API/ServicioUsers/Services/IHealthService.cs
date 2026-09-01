namespace ServicioUsers.Services
{
    public interface IHealthService
    {
        //TODO: Implementar la interfaz del service de health 
        public Task<string?> GetHealth();
    }
}