using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using ServicioShift.Dtos.Close;
using ServicioShift.Dtos.Open;
using ServicioShift.Services;

namespace ServicioShift.Controller
{
    [ApiController]
    [Route("api/[controller]")]
    public class ShiftController : ControllerBase
    {
        private readonly IShiftService _shiftService;

        public ShiftController(IShiftService shiftService)
        {
            _shiftService = shiftService;
        }

        [HttpGet("health")]
        public IActionResult Health()
        {
            try
            {
                return Ok("Servicio Shift funcionando");
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
        [HttpPost("open")]
        public async Task<IActionResult> OpenShift(OpenShiftDto request)
        {
            try
            {
                var shift = await _shiftService.OpenShiftAsync(request);
                return Ok(shift);
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

        [Authorize]
        [HttpPost("close")]
        public async Task<IActionResult> CloseShift(CloseShiftDto request)
        {
            try
            {
                var shift = await _shiftService.CloseShiftAsync(request);
                return Ok(shift);
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