using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace ServicioSales.Dtos.Payment
{
    public class SalePaymentRequestDto
    {
        public int PaymentId {get; set;}
        public int SaleId {get; set;}
        public string Payment_method {get; set;}
        public double Amount {get; set;}
        public double Amount_given {get; set;}
        public double Change_given {get; set;}
        public string Transaction_reference {get; set;}
        public DateTime created_at {get; set;}
    }
}