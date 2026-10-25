using Microsoft.EntityFrameworkCore;
using Npgsql;
using NpgsqlTypes;
using ServicioCut.Data;
using ServicioCut.Dtos;
using ServicioCut.Dtos.DateRange;
using ServicioCut.models.Views;
using ServicioCut.Models.Views;

namespace ServicioCut.Services;

public class CutService : ICutService
{
    private readonly SupaDBContext _context;

    public CutService(SupaDBContext context)
    {
        _context = context;
    }

    public async Task<GetZCutResponseDto> GetZCutsAsync(GetZCutRequestDto request)
    {
        var sql = "SELECT * FROM public.vista_z_cuts WHERE (@p_shiftid IS NULL OR shiftid = @p_shiftid)";

        var parameter = new NpgsqlParameter("p_shiftid", NpgsqlDbType.Integer)
        {
            Value = (object?)request.ShiftId ?? DBNull.Value
        };

        var cuts = await _context.Database
            .SqlQueryRaw<ZCut>(sql, parameter)
            .ToListAsync();

        return new GetZCutResponseDto
        {
            Success = true,
            Message = cuts.Any() ? "Cortes obtenidos con éxito" : "No se encontraron cortes",
            Cuts = cuts
        };
    }

    public async Task<IEnumerable<ZCutItemResponseDto>> GetZCutsByDateRangeAsync(GetZCutsByDateRangeRequestDto request)
        {
            var sql = "SELECT * FROM public.sp_zcuts_by_date_range(@start_date, @end_date)";

            var parameters = new[]
            {
                new NpgsqlParameter("start_date", NpgsqlTypes.NpgsqlDbType.Date)
                {
                    Value = request.StartDate
                },
                new NpgsqlParameter("end_date", NpgsqlTypes.NpgsqlDbType.Date)
                {
                    Value = request.EndDate
                }
            };

            var rawCuts = await _context.Database
                .SqlQueryRaw<ViewZCutByDateRangeModel>(sql, parameters)
                .ToListAsync();

            return rawCuts.Select(c => new ZCutItemResponseDto
            {
                ZCutId = c.ZCutId,
                ShiftId = c.ShiftId,
                CashierId = c.CashierId,
                OpenedAt = c.OpenedAt,
                ClosedAt = c.ClosedAt,
                FirstSaleId = c.FirstSaleId,
                LastSaleId = c.LastSaleId,
                OpeningCash = c.OpeningCash,
                TotalSales = c.TotalSales,
                TotalSalesCount = c.TotalSalesCount,
                ExpectedCash = c.ExpectedCash,
                ExpectedCard = c.ExpectedCard,
                ExpectedTransfer = c.ExpectedTransfer,
                ActualCash = c.ActualCash,
                CashDifference = c.CashDifference,
                Notes = c.Notes
            }).ToList();
        }
}