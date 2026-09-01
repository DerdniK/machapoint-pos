using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace ServicioUsers.Models
{
    [Table("databaseversion")]
    public class DatabaseVersionModel
    {
        [Key]
        [Column("version")]
        public string version {get; set;} = "0.0.0"; //& Valor por defecto 0.0.0
    }
}