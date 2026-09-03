using ServicioProducts.Models.Views;

namespace ServicioProducts.Dtos.Read
{
    public class GetProductResponseDto
    {
        public bool Success {get; set;}
        public string Message {get; set;}
        public List<ViewProductModel> Product {get; set;}
    }
}