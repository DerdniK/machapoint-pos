using ServicioProducts.Dtos;
using ServicioProducts.Dtos.Create;
using ServicioProducts.Dtos.Delete;
using ServicioProducts.Dtos.Read;
using ServicioProducts.Dtos.Search;
using ServicioProducts.Dtos.Update;

namespace ServicioProducts.Services
{
    public interface IProductService
    {
        // Task<IEnumerable<GetAllProductsResponseDto>> GetAllProductsAsync();
        Task<CreateProductResponseDto> CreateProductAsync(CreateProductRequestDto request);
        Task<IEnumerable<ProductItemResponseDto>> GetProductsAsync(GetProductRequestDto request);
        Task<SearchProductResponseDto> SearchProductsAsync(SearchProductRequestDto request);
        Task<DeleteProductResponseDto> DeleteProductAsync(int productId);
        Task<UpdateProductResponseDto> UpdateProductAsync(int productId, UpdateProductRequestDto request);
    }
}