using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace ServicioShift.Dtos
{
    public class ResponseShiftDto
    {
        public string Message {get; set;}
        public bool Status {get; set;}
        public int ShiftId {get; set;}
        public Guid CashierId {get; set;}
        public double ActualCash {get; set;}
        public string Notes {get; set;}
    }
}