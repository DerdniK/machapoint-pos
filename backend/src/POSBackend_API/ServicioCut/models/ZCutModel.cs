using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Linq;
using System.Threading.Tasks;

namespace ServicioCut.Models
{
    public class ZCut
    {
        [Key]
        [Column("zcutid")]
        public int ZCutId {get; set;}
        [Column("shiftid")]
        public int ShiftId {get; set;}
        [Column("cashierid")]
        public Guid CashierId {get; set;}
        [Column("opened_at")]
        public DateTime Opened_At {get; set;}
        [Column("closed_at")]
        public DateTime Closed_At {get; set;}
        [Column("firstsaleid")]
        public int First_SaleId {get; set;}
        [Column("lastsaleid")]
        public int Last_SaleId {get; set;}
        [Column("opening_cash")]
        public double Opening_Cash {get; set;}
        [Column("total_sales")]
        public double Total_Sales {get; set;}
        [Column("total_sales_count")]
        public int Total_Sales_Count {get; set;}
        [Column("expected_cash")]
        public double Expected_Cash {get; set;}
        [Column("expected_card")]
        public double Expected_Card {get; set;}
        [Column("expected_transfer")]
        public double Expected_Transfer {get; set;}
        [Column("actual_cash")]
        public double Actual_Cash {get; set;}
        [Column("cash_difference")]
        public double Cash_Difference {get; set;}
        [Column("notes")]
        public string Notes {get; set;}
    }
}