using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace ServicioSales.Dtos.Search.DateRange
{
    public class SaleItemResponseDto
    {
        public int SaleId { get; set; }
        public int ShiftId { get; set; }
        public Guid CashierId { get; set; }
        public decimal Total { get; set; }
        public string Status { get; set; } = string.Empty;
        public DateTime? CreatedAt { get; set; }
    }
}