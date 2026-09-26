namespace ServicioProducts.Dtos
{
    public class ProductItemResponseDto
    {
        public int Productid { get; set; }
        public string? Name { get; set; }
        public string? SKU { get; set; }
        public ProductTypesResponseDTO Type { get; set; } = new();
        public double Price { get; set; }
        public string? ImageURL { get; set; }
    }
}