using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations.Schema;
using System.Linq;
using System.Threading.Tasks;

namespace ServicioShift.Models
{
    public class ViewShiftModel
    {
        [Column("shiftid")]
        public int ShiftId { get; set; }

        [Column("opening_amount")]
        public decimal OpeningAmount { get; set; }

        [Column("opened_at")]
        public DateTime? OpenedAt { get; set; }

        [Column("status")]
        public string Status { get; set; } = string.Empty;
    }
}