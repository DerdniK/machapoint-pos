using Microsoft.EntityFrameworkCore;
using ServicioShift.Models;

namespace ServicioShift.Data
{
    public class SupaDBContext : DbContext
    {
        public SupaDBContext(DbContextOptions<SupaDBContext> options) : base(options) { } 
        //^ "SupaDBContext" el nombre de la clase a la cual heredamos "DbContext"
        public DbSet<Shift> ShiftsTable {get; set;}
    }
}