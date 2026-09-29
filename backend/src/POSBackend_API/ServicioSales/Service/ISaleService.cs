using ServicioSales.Dtos;
using ServicioSales.Dtos.Product;
using ServicioSales.Dtos.Search;

namespace ServicioSales.Service
{
    public interface ISaleService
    {
        Task<SaleResponseDto> CreateSaleAsync(SaleRequestDto request);
        Task<List<SaleByShiftDto>> GetSalesByShiftAsync(int shiftId);
    }
}