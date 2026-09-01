using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace ServicioUsers.Models
{
    [Table("roles")]
    public class Role
    {
        [Key]
        [Column("roleid")]
        public int Roleid { get; set; }
        [Column("rolename")]
        public string Rolename { get; set; }
        [Column("description")]
        public string Description { get; set; }
    }
}