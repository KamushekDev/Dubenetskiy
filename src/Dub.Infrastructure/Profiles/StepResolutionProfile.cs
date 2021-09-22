using System.Collections.Generic;
using AutoMapper;
using Dub.Infrastructure.Database.Models;
using DubGrpc.StepResolutions;

namespace Dub.Infrastructure.Profiles
{
    public class StepResolutionProfile : Profile
    {
        public StepResolutionProfile()
        {
            CreateMap<AddStepResolutionRequest, ProcessStepResolution>();
            CreateMap<ProcessStepResolution, StepResolutionMsg>();
            CreateMap<IEnumerable<ProcessStepResolution>, GetAllStepResolutionsResponse>()
                .ForMember(x => x.StepResolutions, x => x.MapFrom(y => y));
            CreateMap<IEnumerable<ProcessStepResolution>, GetStepResolutionsResponse>()
                .ForMember(x => x.StepResolutions, x => x.MapFrom(y => y));
        }
    }
}