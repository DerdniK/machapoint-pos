using System.Text.Json;
using Microsoft.EntityFrameworkCore;
using Npgsql;
using NpgsqlTypes;
using ServicioSales.Data;
using ServicioSales.Dtos;

namespace ServicioSales.Service
{
    public class SaleService : ISaleService
    {
        private readonly SupaDBContext _context;
        
        public SaleService(SupaDBContext context)
        {
            _context = context;
        }

        public async Task<SaleResponseDto> CreateSaleAsync(SaleRequestDto request)
        {
            var itemsJson = JsonSerializer.Serialize(request.Products ?? new());
            
            var sql = "SELECT sp_process_sale(@p_shiftid, @p_cashierid, @p_total::numeric, @p_items::jsonb, @p_paymentmethod, @p_amountgiven::numeric, @p_changegiven::numeric, @p_transactionreference)";

            await _context.Database.ExecuteSqlRawAsync(sql,
            new NpgsqlParameter("p_shiftid", request.ShiftId),
            new NpgsqlParameter("p_cashierid", request.CashierId),
            new NpgsqlParameter("p_total", request.Total),
            new NpgsqlParameter("p_items", NpgsqlDbType.Jsonb) { Value = itemsJson },
            new NpgsqlParameter("p_paymentmethod", request.Payment_method),
            new NpgsqlParameter("p_amountgiven", request.Amount_given),
            new NpgsqlParameter("p_changegiven", request.Change_given),
            new NpgsqlParameter("p_transactionreference", request.Transaction_reference)
            );

            return new SaleResponseDto{
                ShiftId = request.ShiftId,
                CashierId = request.CashierId,
                Total = request.Total,
                Status = "Completed",
                Created_at = DateTime.Now,
                ProductsList = request.Products
            };
        }
    }
}