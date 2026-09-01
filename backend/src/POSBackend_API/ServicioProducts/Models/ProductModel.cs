using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace ServicioProducts.Models
{
    [Table("products")]
    public class Products
    {
        [Key]
        [Column("productid")]
        public int Productid{get; set;}

        [Column("name")]
        public string Name{get; set;}

        [Column("sku")]
        public string SKU{get; set;}

        [ForeignKey("typeid")]
        public ProductTypes ProductTypes {get; set;}

        [Column("price")]
        public double Price{get; set;}

        [Column("imageurl")]
        public string? ImageURL{get; set;}
    }
}