using ServicioProducts.Dtos;

namespace ServicioProducts.Services
{
    public interface IProductService
    {
        Task<IEnumerable<GetAllProductsResponseDto>> GetAllProductsAsync();
    }
}