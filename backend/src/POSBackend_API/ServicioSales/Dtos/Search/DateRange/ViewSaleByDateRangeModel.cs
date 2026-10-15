using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations.Schema;
using System.Linq;
using System.Threading.Tasks;

namespace ServicioSales.Dtos.Search.DateRange
{
    public class ViewSaleByDateRangeModel
    {
        [Column("saleid")]
        public int SaleId { get; set; }

        [Column("shiftid")]
        public int ShiftId { get; set; }

        [Column("cashierid")]
        public Guid CashierId { get; set; }

        [Column("total")]
        public decimal Total { get; set; }

        [Column("status")]
        public string Status { get; set; } = string.Empty;

        [Column("created_at")]
        public DateTime? CreatedAt { get; set; }
    }
}