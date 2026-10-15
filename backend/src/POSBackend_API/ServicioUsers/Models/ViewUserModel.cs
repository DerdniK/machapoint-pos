using System.ComponentModel.DataAnnotations.Schema;

namespace ServicioUsers.Models
{
    public class ViewUserModel
    {
        [Column("userid")]
        public Guid UserId { get; set; }

        [Column("username")]
        public string? Username { get; set; } = string.Empty;

        [Column("firstname")]
        public string? First_name { get; set; } = string.Empty;

        [Column("lastname")]
        public string? Last_name { get; set; } = string.Empty;

        [Column("roleid")]
        public int? RoleID { get; set; }

        [Column("created_at")]
        public DateTime? CreatedAt { get; set; }
    }
}