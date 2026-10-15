using ServicioSales.Dtos;
using ServicioSales.Dtos.Product;
using ServicioSales.Dtos.Search;
using ServicioSales.Dtos.Search.DateRange;

namespace ServicioSales.Service
{
    public interface ISaleService
    {
        Task<SaleResponseDto> CreateSaleAsync(SaleRequestDto request);
        Task<List<SaleByShiftDto>> GetSalesByShiftAsync(int shiftId);
        Task<IEnumerable<SaleItemResponseDto>> GetSalesByDateRangeAsync(GetSalesByDateRangeRequestDto request);
    }
}