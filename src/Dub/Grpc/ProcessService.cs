using System.Threading.Tasks;
using AutoMapper;
using Dub.Infrastructure.Database;
using Dub.Infrastructure.Database.Models;
using DubGrpc.Processes;
using Grpc.Core;

namespace Dub.Grpc
{
    public class ProcessService : ProcessesService.ProcessesServiceBase
    {
        private readonly DubContext _db;
        private readonly IMapper _mapper;

        public ProcessService(DubContext db, IMapper mapper)
        {
            _db = db;
            _mapper = mapper;
        }
    }
}