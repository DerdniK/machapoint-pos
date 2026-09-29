using System;
using System.ComponentModel.DataAnnotations.Schema;
using System.Text.Json;
using System.Text.Json.Serialization;

namespace ServicioSales.Dtos.Search
{
    public class SaleByShiftDto
    {
        [Column("saleid")]
        public int SaleId { get; set; }

        [Column("shiftid")]
        public int ShiftId { get; set; }

        [Column("cashier_username")]
        public string CashierUsername { get; set; } = string.Empty;

        [Column("total")]
        public decimal Total { get; set; }

        [Column("status")]
        public string Status { get; set; } = string.Empty;

        [Column("created_at")]
        public DateTime CreatedAt { get; set; }

        [Column("payment_method")]
        public string PaymentMethod { get; set; } = string.Empty;

        [Column("amount_given")]
        public decimal? AmountGiven { get; set; }

        [Column("change_given")]
        public decimal? ChangeGiven { get; set; }

        // Columna oculta que mapea el JSONB de PostgreSQL directamente como texto
        [Column("items")]
        [JsonIgnore]
        public string? RawItems { get; set; }

        // Propiedad expuesta en el JSON que parsea el texto a JSON real automáticamente
        [NotMapped]
        public JsonElement? Items
        {
            get
            {
                if (string.IsNullOrWhiteSpace(RawItems)) return null;
                try
                {
                    return JsonDocument.Parse(RawItems).RootElement;
                }
                catch
                {
                    return null;
                }
            }
        }
    }
}