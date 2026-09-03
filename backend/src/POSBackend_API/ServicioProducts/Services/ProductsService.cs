using Microsoft.EntityFrameworkCore;
using Npgsql;
using ServicioProducts.Data;
using ServicioProducts.Dtos;
using ServicioProducts.Dtos.Create;
using ServicioProducts.Models;

namespace ServicioProducts.Services
{
    public class ProductService : IProductService
    {
        private readonly SupaDBContext _context;
        
        public ProductService(SupaDBContext context)
        {
            _context = context;
        }

        
        public async Task<IEnumerable<GetAllProductsResponseDto>> GetAllProductsAsync()
        {
            
            return await _context.ProductsTable.AsNoTracking()
            .Select(p => new GetAllProductsResponseDto
            {
                Productid = p.Productid,
                Name = p.Name,
                SKU = p.SKU,
                Type = new ProductTypesResponseDTO{
                    Typeid = p.ProductTypes.Typeid ,
                    TypeName = p.ProductTypes.TypeName
                },
                Price = p.Price, 
                ImageURL = p.ImageURL ?? "https://images.vexels.com/media/users/3/144131/isolated/preview/29576a7e0442960346703d3ecd6bac04-icono-de-doodle-de-imagen.png"
            }).ToListAsync();
        }

        public async Task<CreateProductResponseDto> CreateProductAsync(CreateProductRequestDto request)
        {
            var sql = "SELECT sp_a_insert_product(@p_name, @p_sku, @p_precio, @p_typeid, @p_imageurl)";

            await _context.Database.ExecuteSqlRawAsync(sql,
            new NpgsqlParameter("p_name", request.Name),
            new NpgsqlParameter("p_sku", request.SKU),
            new NpgsqlParameter("p_precio", request.Price),
            new NpgsqlParameter("p_typeid", request.TypeId),
            new NpgsqlParameter("p_imageurl", request.ImageURL)
            );

            return new CreateProductResponseDto
            {
              Success = true,
              Message = "",
              SKU = request.SKU
            };
        }
    }
}