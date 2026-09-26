using Microsoft.AspNetCore.Http.HttpResults;
using Microsoft.EntityFrameworkCore;
using Npgsql;
using ServicioProducts.Data;
using ServicioProducts.Dtos;
using ServicioProducts.Dtos.Create;
using ServicioProducts.Dtos.Read;
using ServicioProducts.Dtos.Search;
using ServicioProducts.Models.Views;

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
              Message = "Producto creado con exito!",
              SKU = request.SKU
            };
        }

        public async Task<GetProductResponseDto> GetProductsAsync(GetProductRequestDto request)
        {
            var sql = "SELECT * FROM public.sp_view_products(@p_productid)";

            var parameter = new NpgsqlParameter("p_productid", NpgsqlTypes.NpgsqlDbType.Integer)
            {
                Value = (object?)request.ProductId ?? DBNull.Value
            };

            var products = await _context.Database
            .SqlQueryRaw<ViewProductModel>(sql, parameter)
            .ToListAsync();

            return new GetProductResponseDto
            {
                Success = true,
                Message = products.Any() ? "Productos obtenidos con éxito" : "No se encontraron productos",
                Product = products
            };
        }

        public async Task<SearchProductResponseDto> SearchProductsAsync(SearchProductRequestDto request)
        {
            var param = new NpgsqlParameter("p_name", NpgsqlTypes.NpgsqlDbType.Text)
            {
                Value = string.IsNullOrWhiteSpace(request?.Name) ? (object)DBNull.Value : request.Name
            };

            // Consultamos usando el DTO que coincide exactamente con las columnas de Postgres
            var result = await _context.Database
                .SqlQueryRaw<ProductDbResult>(
                    "SELECT productid, name, sku, typeid, price, imageurl FROM public.sp_search_product(@p_name)",
                    param
                )
                .ToListAsync();

            if (result == null)
            {
                return new SearchProductResponseDto
                {
                    Success = false,
                    Message = "No se encontró ningún producto con ese nombre."
                };
            }

            return new SearchProductResponseDto
            {
                Success = true,
                Message = "El/los producto/s que buscabas si existe/n",
                Data = result.Select((ProductDbResult r) => new ProductItemDto
                {
                    ProductId = r.productid,
                    Name = r.name,
                    SKU = r.sku,
                    TypeId = r.typeid,
                    Price = (double)r.price,
                    ImageURL = r.imageurl
                }).ToList()
            };
        }
    }
}