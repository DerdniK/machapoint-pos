using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace ServicioSales.Models
{
    public class SaleItems
    {
        [Key]
        [Column("saleitemid")]
        public int SaleItemId {get; set;}
        
        [Column("saleid")]
        public int SaleId {get; set;}
        [Column("productid")]
        public int ProductId {get; set;}
        [Column("unit_price")]
        public double Unit_Price {get; set;}
        [Column("quantity")]
        public int Quantity { get; set; }
        [Column("subtotal")]
        public double Subtotal{ get; set; }
    }
}