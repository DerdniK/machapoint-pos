using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace ServicioProducts.Models.Views
{
    public class ViewProductModel
    {
        [Key]
        [Column("productid")]
        public int ProductId {get; set;}
        [Column("name")]
        public string Name {get; set;}
        [Column("sku")]
        public string SKU {get; set;}
        [Column("price")]
        public double Price {get; set;}
        [Column("imageurl")]
        public string ImageURL {get; set;}
    }
}