using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace ServicioShift.Dtos.Open
{
    public class OpenResponseShiftDto
    {
        public string Message {get; set;}
        public bool Status {get; set;}
        public double ActualCash {get; set;}
        public int ShiftId {get; set;}
    }
}