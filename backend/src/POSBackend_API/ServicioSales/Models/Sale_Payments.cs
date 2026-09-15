using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace ServicioSales.Models
{
    public class SalePayments
    {
        [Key]
        [Column("paymentid")]
        public int PaymentId{ get; set; }
        [Column("saleid")]
        public int SaleId{ get; set; }
        [Column("payment_method")]
        public string Payment_Method {get; set;}
        [Column("amount")]
        public double Amount{ get; set; }
        [Column("amount_given")]
        public double Amount_Given {get; set;}
        [Column("change_given")]
        public double Change_Given {get; set;}
        [Column("transaction_refrence")]
        public string Transaction_Reference {get; set;}
        [Column("created_at")]
        public DateTime Created_At {get; set;}

    }
}