using Microsoft.EntityFrameworkCore;
using Npgsql;
using NpgsqlTypes;
using ServicioCut.Data;
using ServicioCut.Dtos;
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
}