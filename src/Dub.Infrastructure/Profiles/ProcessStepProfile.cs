using System.Collections;
using System.Collections.Generic;
using AutoMapper;
using Dub.Infrastructure.Database.Models;
using DubGrpc.ProcessSteps;

namespace Dub.Infrastructure.Profiles
{
    public class ProcessStepProfile : Profile
    {
        public ProcessStepProfile()
        {
            CreateMap<AddProcessStepRequest, ProcessStep>();
            CreateMap<ProcessStep, ProcessStepMsg>();
            CreateMap<ProcessStep, GetProcessStepResponse>()
                .ForMember(x => x.ProcessStep, x => x.MapFrom(y => y));
            CreateMap<IEnumerable<ProcessStep>, GetProcessStepsResponse>()
                .ForMember(x => x.ProcessSteps, x => x.MapFrom(y => y));
        }
    }
}