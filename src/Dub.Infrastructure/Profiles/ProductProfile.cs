using System.Collections.Generic;
using AutoMapper;
using Dub.Infrastructure.Database.Models;
using DubGrpc.Products;

namespace Dub.Infrastructure.Profiles
{
    public class ProductProfile : Profile
    {
        public ProductProfile()
        {
            CreateMap<AddProductRequest, Product>()
                .ForMember(x => x.ClassId, x => x.MapFrom(y => y.ClassId))
                .ForMember(x => x.Name, x => x.MapFrom(y => y.Name))
                .ForMember(x => x.BaseId, x =>
                {
                    x.PreCondition(y => y.HasBaseId);
                    x.MapFrom(y => y.BaseId);
                })
                .ForMember(x => x.Version, x => x.MapFrom(y => y.Version))
                ;

            CreateMap<IEnumerable<Product>, GetProductsResponse>()
                .ForMember(x => x.Products, x =>
                {
                    x.UseDestinationValue();
                    x.MapFrom(y => y);
                });

            CreateMap<Product, ProductMsg>()
                .ForMember(x => x.Id, x => x.MapFrom(y => y.Id))
                .ForMember(x => x.Name, x => x.MapFrom(y => y.Name))
                .ForMember(x => x.Version, x => x.MapFrom(y => y.Version))
                .ForMember(x => x.ClassId, x => x.MapFrom(y => y.ClassId))
                .ForMember(x => x.BaseId, x =>
                {
                    x.PreCondition(y => y.BaseId.HasValue);
                    x.MapFrom(y => y.BaseId);
                });
        }
    }
}