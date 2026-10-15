using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace ServicioSales.Dtos.Search.DateRange
{
    public class GetSalesByDateRangeRequestDto
    {
        public DateOnly StartDate { get; set; }
        public DateOnly EndDate { get; set; }
    }
}