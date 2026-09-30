using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Security.Cryptography.X509Certificates;

namespace ServicioSales.Models
{
    public class Sales
    {
        [Key]
        [Column("saleid")]
        public int SaleId { get; set; }
        [Column("shiftid")]
        public int ShiftId { get; set; }
        [Column("cashiedid")]
        public Guid CashierId { get; set; }
        [Column("total")]
        public double Total { get; set; }
        [Column("status")]
        public string Status { get; set; }
        [Column("created_at")]
        public DateTime Created_at { get; set; }
    }
}