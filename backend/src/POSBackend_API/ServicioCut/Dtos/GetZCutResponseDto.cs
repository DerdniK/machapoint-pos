using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using ServicioCut.Models;
using ServicioCut.Models.Views;

namespace ServicioCut.Dtos
{
    public class GetZCutResponseDto
    {
        public bool Success { get; set; }
        public string Message { get; set; }
        public List<ZCut> Cuts { get; set; }
    }
}