namespace ServicioProducts.Dtos
{
    public class GetAllProductsResponseDto
    {
        public int Productid{get; set;}
        public string? Name{get; set;}
        public string? SKU{get; set;}
        public ProductTypesResponseDTO Type {get; set;}
        public double Price{get; set;}
        public string ImageURL{get; set;}
    }
}