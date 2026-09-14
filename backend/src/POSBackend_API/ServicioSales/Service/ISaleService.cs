using ServicioSales.Dtos;
using ServicioSales.Dtos.Product;

namespace ServicioSales.Service
{
    public interface ISaleService
    {
        Task<SaleResponseDto> CreateSaleAsync(SaleRequestDto request);
    }
}