using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using Npgsql;
using ServicioShift.Data;
using ServicioShift.Dtos;
using ServicioShift.Dtos.Close;
using ServicioShift.Dtos.Open;

namespace ServicioShift.Services
{
    public class ShiftService : IShiftService
    {
        public readonly SupaDBContext _context;
        public ShiftService(SupaDBContext context)
        {
            _context = context;
        }

        public async Task<OpenResponseShiftDto> OpenShiftAsync(OpenShiftDto request)
        {
            var sql = "SELECT sp_open_shift(@p_cashierid::uuid, @p_opening_amount::numeric)";

            await _context.Database.ExecuteSqlRawAsync(sql,
            new NpgsqlParameter("p_cashierid", request.CashierId),
            new NpgsqlParameter("p_opening_amount", request.OpeningAmount)
            );

            return new OpenResponseShiftDto
            {
                Message = "Turno iniciado correctamente!",
                Status = true,
                ActualCash = request.OpeningAmount
            };
        }

        public async Task<CloseResponseShiftDto> CloseShiftAsync(CloseShiftDto request)
        {
            var sql = "SELECT sp_close_shift_z_cut(@p_shiftid, @p_cashierid::uuid, @p_actual_cash::numeric, @p_notes::text)";

            await _context.Database.ExecuteSqlRawAsync(sql,
            new NpgsqlParameter("p_shiftid", request.ShiftId),
            new NpgsqlParameter("p_cashierid", request.CashierId),
            new NpgsqlParameter("p_actual_cash", request.ActualCash),
            new NpgsqlParameter("p_notes", request.Notes)
            );

            return new CloseResponseShiftDto
            {
                Message = "Turno Cerrado correctamente!",
                Status = true,
                ShiftId = request.ShiftId,
                CashierId = request.CashierId,
                ActualCash = request.ActualCash,
                Notes = request.Notes

            };
        }
    }
}