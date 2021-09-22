using System.Threading.Tasks;
using AutoMapper;
using Dub.Core.Exceptions;
using Dub.Infrastructure.Database;
using Dub.Infrastructure.Database.Models;
using DubGrpc.ProcessSteps;
using Grpc.Core;
using Microsoft.EntityFrameworkCore;

namespace Dub.Grpc
{
    public class ProcessStepService : ProcessStepsService.ProcessStepsServiceBase
    {
        private readonly DubContext _db;
        private readonly IMapper _mapper;

        public ProcessStepService(DubContext db, IMapper mapper)
        {
            _db = db;
            _mapper = mapper;
        }

        public override async Task<AddProcessStepResponse> AddProcessStep(AddProcessStepRequest request,
            ServerCallContext context)
        {
            var entity = _mapper.Map<ProcessStep>(request);

            var result = await _db.ProcessSteps.AddAsync(entity);

            await _db.SaveChangesAsync();

            return new AddProcessStepResponse { Id = result.Entity.Id };
        }

        public override async Task<GetProcessStepResponse> GetProcessStep(GetProcessStepRequest request,
            ServerCallContext context)
        {
            var entity = await _db.ProcessSteps.FindAsync(request.Id);

            if (entity is null)
                throw new NotFoundException();

            return _mapper.Map<GetProcessStepResponse>(entity);
        }

        public override async Task<GetProcessStepsResponse> GetProcessSteps(GetProcessStepsRequest request,
            ServerCallContext context)
        {
            var entities = await _db.ProcessSteps.ToListAsync();

            return _mapper.Map<GetProcessStepsResponse>(entities);
        }
    }
}