using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using ServicioCut.Dtos;

namespace ServicioCut.Services
{
    public interface ICutService
    {
        Task<GetZCutResponseDto> GetZCutsAsync(GetZCutRequestDto request);
    }
}