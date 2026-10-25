using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace ServicioShift.dtos.GetShift
{
    public class GetShiftRequestDto
    {
        public Guid CashierId { get; set; }
    }
}