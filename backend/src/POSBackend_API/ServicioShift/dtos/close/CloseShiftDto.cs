using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace ServicioShift.Dtos.Close
{
    public class CloseShiftDto
    {
        public int ShiftId {get; set;}
        public Guid CashierId {get; set;}
        public double ActualCash {get; set;}
        public string Notes {get; set;}
    }
}