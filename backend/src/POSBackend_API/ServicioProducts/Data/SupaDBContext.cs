using Microsoft.EntityFrameworkCore;
using ServicioProducts.Models;

namespace ServicioProducts.Data
{
    public class SupaDBContext : DbContext
    {
        public SupaDBContext(DbContextOptions<SupaDBContext> options) : base(options) { } 
        //^ "SupaDBContext" el nombre de la clase a la cual heredamos "DbContext"

        // public DbSet<DatabaseVersionModel> DatabaseVersion { get; set; } 
        //& Aqui asignamos que el model de version es "DatabaseVersionModel" y se va a llamar "DatabaseVersion"
        // public DbSet<User> UserTable {get; set;}
        public DbSet<Products> ProductsTable {get; set;}
        public DbSet<ProductTypes> ProductsTypeTable {get; set;}
    }
}