using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
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
    }
}