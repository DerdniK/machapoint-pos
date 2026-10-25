using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace ServicioShift.dtos.GetShift
{
    public class ShiftItemResponseDto
    {
        public int ShiftId { get; set; }
        public decimal OpeningAmount { get; set; }
        public DateTime? OpenedAt { get; set; }
        public string Status { get; set; } = string.Empty;
    }
}