using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations.Schema;
using System.Linq;
using System.Threading.Tasks;

namespace ServicioCut.models.Views
{
    public class ViewZCutByDateRangeModel
    {
        [Column("zcutid")]
        public int ZCutId { get; set; }

        [Column("shiftid")]
        public int ShiftId { get; set; }

        [Column("cashierid")]
        public Guid CashierId { get; set; }

        [Column("opened_at")]
        public DateTime? OpenedAt { get; set; }

        [Column("closed_at")]
        public DateTime? ClosedAt { get; set; }

        [Column("firstsaleid")]
        public int? FirstSaleId { get; set; }

        [Column("lastsaleid")]
        public int? LastSaleId { get; set; }

        [Column("opening_cash")]
        public decimal OpeningCash { get; set; }

        [Column("total_sales")]
        public decimal TotalSales { get; set; }

        [Column("total_sales_count")]
        public int TotalSalesCount { get; set; }

        [Column("expected_cash")]
        public decimal ExpectedCash { get; set; }

        [Column("expected_card")]
        public decimal ExpectedCard { get; set; }

        [Column("expected_transfer")]
        public decimal ExpectedTransfer { get; set; }

        [Column("actual_cash")]
        public decimal ActualCash { get; set; }

        [Column("cash_difference")]
        public decimal CashDifference { get; set; }

        [Column("notes")]
        public string? Notes { get; set; }
    }
}