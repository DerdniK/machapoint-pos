using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace ServicioSales.Models
{
    [Table("product_types")]
    public class ProductTypes
    {
        [Key]
        [Column("typeid")]
        public int Typeid {get; set;}
        [Column("typename")]
        public string TypeName{get; set;}
    }
}