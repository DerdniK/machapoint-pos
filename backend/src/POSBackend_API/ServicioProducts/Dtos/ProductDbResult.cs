// DTO exclusivo para mapear la salida del SP
public class ProductDbResult
{
    public int productid { get; set; }
    public string name { get; set; } = string.Empty;
    public string sku { get; set; } = string.Empty;
    public int typeid { get; set; }
    public decimal price { get; set; }
    public string imageurl { get; set; } = string.Empty;
}