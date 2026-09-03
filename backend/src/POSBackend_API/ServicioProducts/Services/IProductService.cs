using ServicioProducts.Dtos;
using ServicioProducts.Dtos.Create;

namespace ServicioProducts.Services
{
    public interface IProductService
    {
        Task<IEnumerable<GetAllProductsResponseDto>> GetAllProductsAsync();
        Task<CreateProductResponseDto> CreateProductAsync(CreateProductRequestDto request);
    }
}