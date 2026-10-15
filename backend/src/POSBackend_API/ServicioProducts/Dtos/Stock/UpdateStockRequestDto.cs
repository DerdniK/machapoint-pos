namespace ServicioProducts.Dtos.Products.Stock
{
    public class UpdateStockRequestDto
    {
        public int ProductId { get; set; }
        public int Stock { get; set; }
        // Opcional: si es null, la función SQL aplicará la suma por default
        public bool? IsAdjustment { get; set; }
    }
}