using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace ServicioSales.Dtos.Product
{
    public class SaleProductResponseDto
    {
        public int ProductId {get; set;}
        public double Unit_price {get; set;}
        public int Quantity {get; set;}
        public double Subtotal {get; set;}
    }
}