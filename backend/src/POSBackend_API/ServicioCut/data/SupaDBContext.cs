using Microsoft.EntityFrameworkCore;
using ServicioCut.Models;

namespace ServicioCut.Data
{
    public class SupaDBContext : DbContext
    {
        public SupaDBContext(DbContextOptions<SupaDBContext> options) : base(options) { } 
        //^ "SupaDBContext" el nombre de la clase a la cual heredamos "DbContext"
        public DbSet<ZCut> ZCutsTable {get; set;}
    }
}