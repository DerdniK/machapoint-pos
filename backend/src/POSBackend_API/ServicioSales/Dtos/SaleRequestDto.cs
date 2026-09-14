using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace ServicioSales.Dtos
{
    public class SaleRequestDto
    {
        public int SaleId {get; set;}
        public int ShiftId {get; set;}
        public int CashierId {get; set;}
        public double Total {get; set;}
        public string Status {get; set;}
        public DateTime Created_at {get; set;}
    }
}