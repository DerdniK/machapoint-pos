using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace ServicioUsersById.Dtos.Auth.Read
{
    public class GetUsersByIdRequestDto
    {
        public Guid? UserId { get; set; }
    }
}