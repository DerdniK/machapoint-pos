using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http.HttpResults;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using ServicioSales.Dtos;
using ServicioSales.Service;

namespace ServicioSales.Controller
{
    [ApiController]
    [Route("api/[controller]")]
    public class SaleController : ControllerBase
    {
        private readonly ISaleService _saleService;

        public SaleController(ISaleService saleService)
        {
            _saleService = saleService;
        }

        [HttpGet("health")]
        public IActionResult Health()
        {
            try
            {
                return Ok(true);
            }
            catch (Exception ex)
            {
                return StatusCode(StatusCodes.Status500InternalServerError, new 
                { 
                    message = "El servicio esta caido :(",
                    detail = ex.Message 
                });
            }
            
        }

        [Authorize]
        [HttpPost]
        public async Task<IActionResult> CreateSale(SaleRequestDto request)
        {
            try
            {
                var sale = await _saleService.CreateSaleAsync(request);
                return StatusCode(StatusCodes.Status201Created, sale);
            }
            catch (Exception ex)
            {
                return StatusCode(StatusCodes.Status500InternalServerError, new 
                { 
                    message = "Ocurrió un error interno al registrar la venta.",
                    detail = ex.Message 
                });
            }
        }

        [Authorize]
        [HttpGet("by-shift")]
        public async Task<IActionResult> GetSalesByShift([FromQuery] int shiftId)
        {
            try
            {
                var sales = await _saleService.GetSalesByShiftAsync(shiftId);
                return Ok(new
                {
                    success = true,
                    totalSales = sales.Count,
                    data = sales
                });
            }
            catch (Exception ex)
            {
                return StatusCode(StatusCodes.Status500InternalServerError, new
                {
                    message = "Ocurrió un error al obtener las ventas del turno.",
                    detail = ex.Message
                });
            }
        }

    }
}