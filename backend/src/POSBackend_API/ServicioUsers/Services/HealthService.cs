using Microsoft.EntityFrameworkCore;
using ServicioUsers.Data;
using ServicioUsers.Dtos;

namespace ServicioUsers.Services
{
 public class HealthService : IHealthService
    {
        //TODO: Implementar el service de health 
        private readonly SupaDBContext _context;

        public HealthService(SupaDBContext context)
        {
            _context = context;
        }

        public async Task<string?> GetHealth()
        {
            var version = _context.DatabaseVersion
            .AsNoTracking()
            .Select(x => x.version)
            .FirstOrDefaultAsync();
            
            return await version;
        }
    }   
}