using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using ServicioShift.Dtos;
using ServicioShift.Dtos.Close;
using ServicioShift.Dtos.Open;

namespace ServicioShift.Services
{
    public interface IShiftService
    {
        Task<OpenResponseShiftDto> OpenShiftAsync(OpenShiftDto request);
        Task<CloseResponseShiftDto> CloseShiftAsync(CloseShiftDto request);
    }
}