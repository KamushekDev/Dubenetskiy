using System.Collections.Generic;
using AutoMapper;
using Dub.Infrastructure.Database.Models;
using DubGrpc.ProductClasses;

namespace Dub.Infrastructure.Profiles
{
    public class ProductClassProfile : Profile
    {
        public ProductClassProfile()
        {
            CreateMap<AddProductClassRequest, ProductClass>()
                .ForMember(x => x.Name, x => x.MapFrom(y => y.Name))
                .ForMember(x => x.ParentId, x =>
                {
                    x.AllowNull();
                    x.PreCondition(y => y.HasParentId);
                    x.MapFrom(y => y.ParentId);
                });
            CreateMap<ProductClass, AddProductClassResponse>().ForMember(x => x.Id, x => x.MapFrom(y => y.Id));


            CreateMap<ProductClass, ProductClassMsg>()
                .ForMember(x => x.Id, x => x.MapFrom(y => y.Id))
                .ForMember(x => x.Name, x => x.MapFrom(y => y.Name))
                .ForMember(x => x.ParentId, x =>
                {
                    x.AllowNull();
                    x.PreCondition(y => y.ParentId is not null);
                    x.MapFrom(y => y.ParentId);
                })
                .ForAllOtherMembers(x => x.Ignore());

            CreateMap<IEnumerable<ProductClass>, GetProductClassesResponse>()
                .ForMember(x => x.ProductClasses, x =>
                {
                    x.UseDestinationValue();
                    x.MapFrom(y => y);
                });

            CreateMap<ProductClass, GetProductClassResponse>()
                .ForMember(x => x.ProductClass, x => x.MapFrom(y => y));
        }
    }
}