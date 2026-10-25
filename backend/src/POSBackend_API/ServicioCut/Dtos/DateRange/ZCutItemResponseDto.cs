using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace ServicioCut.Dtos.DateRange
{
    public class ZCutItemResponseDto
    {
        public int ZCutId { get; set; }
        public int ShiftId { get; set; }
        public Guid CashierId { get; set; }
        public DateTime? OpenedAt { get; set; }
        public DateTime? ClosedAt { get; set; }
        public int? FirstSaleId { get; set; }
        public int? LastSaleId { get; set; }
        public decimal OpeningCash { get; set; }
        public decimal TotalSales { get; set; }
        public int TotalSalesCount { get; set; }
        public decimal ExpectedCash { get; set; }
        public decimal ExpectedCard { get; set; }
        public decimal ExpectedTransfer { get; set; }
        public decimal ActualCash { get; set; }
        public decimal CashDifference { get; set; }
        public string? Notes { get; set; }
    }
}