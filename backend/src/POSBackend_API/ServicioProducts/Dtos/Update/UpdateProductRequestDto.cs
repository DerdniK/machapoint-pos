namespace ServicioProducts.Dtos.Update
{
    public class UpdateProductRequestDto
    {
        public string? Name { get; set; }
        public string? SKU { get; set; }
        public int? TypeId { get; set; }
        public decimal? Price { get; set; }
        public string? ImageURL { get; set; }
    }
}