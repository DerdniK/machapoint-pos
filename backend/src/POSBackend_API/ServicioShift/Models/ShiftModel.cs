using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Linq;
using System.Threading.Tasks;

namespace ServicioShift.Models
{
    public class Shift
    {
        [Key]
        [Column("shiftid")]
        public int ShiftId {get; set;}
        [Column("cahierid")]
        public Guid CashierId {get; set;}
        [Column("opening_amount")]
        public double Opening_amount {get; set;}
        [Column("status")]
        public string? Status {get; set;}
        [Column("opened_at")]
        public DateTime Opened_at {get; set;}
        [Column("closed_at")]
        public DateTime Closed_at {get; set;}

    }
}