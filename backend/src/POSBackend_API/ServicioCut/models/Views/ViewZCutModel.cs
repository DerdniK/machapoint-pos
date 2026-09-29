using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace ServicioCut.Models.Views;

public class ZCut
{
    [Key]
    [Column("zcutid")]
    public int ZcutId { get; set; } // int4 -> int

    [Column("shiftid")]
    public int ShiftId { get; set; } // int4 -> int

    [Column("cashier_username")]
    public string CashierUsername { get; set; } = string.Empty; // text/varchar -> string

    [Column("opened_at")]
    public DateTime OpenedAt { get; set; } // timestamptz -> DateTime

    [Column("closed_at")]
    public DateTime ClosedAt { get; set; } // timestamptz -> DateTime

    [Column("opening_cash")]
    public decimal OpeningCash { get; set; } // numeric -> decimal

    [Column("total_sales")]
    public decimal TotalSales { get; set; } // numeric -> decimal

    [Column("total_sales_count")]
    public int TotalSalesCount { get; set; } // int4 -> int

    [Column("expected_cash")]
    public decimal ExpectedCash { get; set; } // numeric -> decimal

    [Column("actual_cash")]
    public decimal ActualCash { get; set; } // numeric -> decimal

    [Column("cash_difference")]
    public decimal CashDifference { get; set; } // numeric -> decimal

    [Column("audit_status")]
    public string AuditStatus { get; set; } = string.Empty; // text -> string

    [Column("notes")]
    public string? Notes { get; set; } // text -> string? nullable
}