using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using ServicioProducts.Dtos.Create;
using ServicioProducts.Services;

namespace ServicioProducts.Controllers
{
    [ApiController]
    [Route("api/products/[controller]")]
    public class ProductController : ControllerBase
    {
        private readonly IProductService _productService;

        public ProductController(IProductService productService)
        {
            _productService = productService;
        }


        [Authorize]
        [HttpGet]
        public async Task<IActionResult> GetAllProducts()
        {
            try
            {
                var product = await _productService.GetAllProductsAsync();
                return Ok(product);
            }
            catch (System.Exception ex)
            {
                
                return StatusCode(500, new { success = false, message = ex.Message });
            }
        }

        [HttpPost]
        public async Task<IActionResult> CreateProduct(CreateProductRequestDto request)
        {
            try
            {
                var product = await _productService.CreateProductAsync(request);

                if (!product.Success)
                {
                    return BadRequest(product);
                }
                return(Ok(product));
            }
            catch (Exception ex)
            {
                
                return StatusCode(500, new
                {
                    Error = ex.Message,
                    InnerError = ex.InnerException?.Message,
                    Stack = ex.StackTrace
                });
            }
        }
    }
}