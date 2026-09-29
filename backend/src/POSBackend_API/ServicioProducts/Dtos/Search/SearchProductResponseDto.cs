namespace ServicioProducts.Dtos.Search
{
    public class SearchProductResponseDto
    {
        public bool Success {get; set;}
        public string Message {get; set;}
        public List<ProductItemDto> Data { get; set; }
    }
}