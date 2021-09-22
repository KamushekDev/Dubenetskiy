using System.Linq;
using System.Threading.Tasks;
using AutoMapper;
using Dub.Core.Exceptions;
using Dub.Infrastructure.Database;
using Dub.Infrastructure.Database.Models;
using DubGrpc.StepResolutions;
using Grpc.Core;
using Microsoft.EntityFrameworkCore;

namespace Dub.Grpc
{
    public class StepResolutionService : StepResolutionsService.StepResolutionsServiceBase
    {
        private readonly DubContext _db;
        private readonly IMapper _mapper;

        public StepResolutionService(DubContext db, IMapper mapper)
        {
            _db = db;
            _mapper = mapper;
        }

        public override async Task<AddStepResolutionResponse> AddStepResolution(AddStepResolutionRequest request,
            ServerCallContext context)
        {
            var step = await _db.ProcessSteps.FindAsync(request.CurrentStepId);
            if (step is null)
                throw new NotFoundException();
            step = await _db.ProcessSteps.FindAsync(request.NextStepId);
            if (step is null)
                throw new NotFoundException();


            var entity = _mapper.Map<ProcessStepResolution>(request);

            var result = await _db.ProcessStepResolutions.AddAsync(entity);

            await _db.SaveChangesAsync();

            return new AddStepResolutionResponse { Id = result.Entity.Id };
        }

        public override async Task<EditStepResolutionResponse> EditStepResolution(EditStepResolutionRequest request,
            ServerCallContext context)
        {
            var entity = await _db.ProcessStepResolutions.FindAsync(request.Id);
            if (entity is null)
                throw new NotFoundException();

            _mapper.Map(request, entity);

            _db.Update(entity);
            await _db.SaveChangesAsync();
            return new EditStepResolutionResponse();
        }

        public override async Task<GetAllStepResolutionsResponse> GetAllStepResolutions(
            GetAllStepResolutionsRequest request,
            ServerCallContext context)
        {
            var entities = await _db.ProcessStepResolutions.ToListAsync();

            return _mapper.Map<GetAllStepResolutionsResponse>(entities);
        }

        public override async Task<GetStepResolutionsResponse> GetStepResolutions(GetStepResolutionsRequest request,
            ServerCallContext context)
        {
            var entities = await _db.ProcessStepResolutions.Where(x => x.CurrentStepId == request.FromStepId)
                .ToListAsync();

            return _mapper.Map<GetStepResolutionsResponse>(entities);
        }
    }
}