using System.Collections.Generic;
using AutoMapper;
using Dub.Infrastructure.Database.Models;
using DubApi;

namespace Dub.Infrastructure
{
    public class AutoMapperProfile : Profile
    {
        public AutoMapperProfile()
        {
            CreateMap<AddProductClassRequest, ProductClass>()
                .ForMember(x => x.Name, x => x.MapFrom(y => y.Name))
                .ForMember(x => x.ParentId, x =>
                {
                    x.PreCondition(y => y.HasParentId);
                    x.MapFrom(y => y.ParentId);
                });
            CreateMap<ProductClass, AddProductClassResponse>().ForMember(x => x.Id, x => x.MapFrom(y => y.Id));


            CreateMap<ProductClass, ProductClassMsg>()
                .ReverseMap()
                .ForMember(x => x.Id, x => x.MapFrom(y => y.Id))
                .ForMember(x => x.Name, x => x.MapFrom(y => y.Name))
                .ForMember(x => x.ParentId, x => x.MapFrom(y => y.ParentId))
                .ForAllOtherMembers(x => x.Ignore());

            CreateMap<IEnumerable<ProductClass>, GetProductClassesResponse>()
                .ForMember(x => x.ProductClasses, x =>
                {
                    x.UseDestinationValue();
                    x.MapFrom(y => y);
                });
        }
    }
}