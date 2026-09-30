using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using ServicioSales.Dtos.Product;

namespace ServicioSales.Dtos
{
    public class SaleResponseDto
    {
        public int ShiftId {get; set;}
        public Guid CashierId {get; set;}
        public List<SaleProductResponseDto> ProductsList {get; set;}
        public double Total {get; set;}
        public string Status {get; set;}
        public DateTime Created_at {get; set;}
    }
}