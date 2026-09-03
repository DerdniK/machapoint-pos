namespace ServicioProducts.Dtos.Create
{
    public class CreateProductRequestDto
    {
        public int Productid {get; set;}
        public string Name {get; set;}
        public string SKU {get; set;}
        public int TypeId {get; set;}
        public double Price {get; set;}
        public string ImageURL {get; set;}
    }
}