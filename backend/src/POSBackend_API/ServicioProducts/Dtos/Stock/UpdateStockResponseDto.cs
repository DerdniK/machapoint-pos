namespace ServicioProducts.Dtos.Products.Stock
{

    public class UpdateStockResponseDto
    {
        public bool Success { get; set; }
        public string Message { get; set; } = string.Empty;
        public int ProductId { get; set; }
    }
}