using ServicioProducts.Dtos;
using ServicioProducts.Dtos.Create;
using ServicioProducts.Dtos.Read;

namespace ServicioProducts.Services
{
    public interface IProductService
    {
        Task<IEnumerable<GetAllProductsResponseDto>> GetAllProductsAsync();
        Task<CreateProductResponseDto> CreateProductAsync(CreateProductRequestDto request);
        Task<GetProductResponseDto> GetProductsAsync(GetProductRequestDto request);

    }
}