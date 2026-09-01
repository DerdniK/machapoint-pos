using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using Microsoft.AspNetCore.Identity;

namespace ServicioUsers.Models
{
    [Table("users")]
    public class User
    {
        [Key]
        [Column ("userid")]
        public Guid UserId {get; set;} = Guid.NewGuid();

        [Column ("password")]
        public string PasswordHash {get; set;} = string.Empty;

        [Column ("firstname")]
        public string First_name {get; set;} = string.Empty;

        [Column ("lastname")]
        public string Last_name{get; set;} = string.Empty;

        [Column ("roleid")]
        public int RoleID {get; set;}

        [Column ("created_at")]
        public DateTime CreatedAt {get; set;} = DateTime.UtcNow;

        [Column ("username")]
        public string Username {get; set;} = string.Empty;
    }
}