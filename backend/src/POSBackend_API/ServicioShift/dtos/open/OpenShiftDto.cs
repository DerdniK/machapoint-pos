using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace ServicioShift.Dtos.Open
{
    public class OpenShiftDto
    {
        public Guid CashierId {get; set;}
        public double OpeningAmount {get; set;}
    }
}