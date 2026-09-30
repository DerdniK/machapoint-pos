public class ProductItemDto
    {
        public int ProductId { get; set; }
        public string Name { get; set; } = string.Empty;
        public string SKU { get; set; } = string.Empty;
        public int TypeId { get; set; }
        public double Price { get; set; }
        public string ImageURL { get; set; } = string.Empty;
    }