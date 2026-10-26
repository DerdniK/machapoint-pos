using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using ServicioCut.Dtos;
using ServicioCut.Dtos.DateRange;

namespace ServicioCut.Services
{
    public interface ICutService
    {
        Task<GetZCutResponseDto> GetZCutsAsync(GetZCutRequestDto request);
        Task<IEnumerable<ZCutItemResponseDto>> GetZCutsByDateRangeAsync(GetZCutsByDateRangeRequestDto request);
    }
}