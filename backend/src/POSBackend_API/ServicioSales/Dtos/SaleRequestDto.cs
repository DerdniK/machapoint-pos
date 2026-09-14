using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using ServicioSales.Dtos.Product;

namespace ServicioSales.Dtos
{
    public class SaleRequestDto
    {
        public int ShiftId {get; set;}
        public Guid CashierId {get; set;}
        public double Total {get; set;}
        public string Payment_method { get; set; } = string.Empty;
        public double Amount_given { get; set; }
        public double Change_given { get; set; }
        public string? Transaction_reference { get; set; }
        public List<SaleProductResponseDto> Products { get; set; }
    }
}