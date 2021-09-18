using System.Threading.Tasks;
using AutoMapper;
using Dub.Infrastructure.Database;
using Dub.Infrastructure.Database.Models;
using DubApi;
using Grpc.Core;
using Microsoft.EntityFrameworkCore;

namespace Dub.Grpc
{
    public class DubService : DubApi.Dub.DubBase
    {
        private readonly DubContext _db;
        private readonly IMapper _mapper;

        public DubService(DubContext db, IMapper mapper)
        {
            _db = db;
            _mapper = mapper;
        }

        public override async Task<AddProductClassResponse> AddProductClass(AddProductClassRequest request,
            ServerCallContext context)
        {
            var entity = _mapper.Map<ProductClass>(request);

            var result = await _db.ProductClasses.AddAsync(entity, context.CancellationToken);

            await _db.SaveChangesAsync();

            return _mapper.Map<AddProductClassResponse>(result.Entity);
        }

        public override async Task<GetProductClassesResponse> GetProductClasses(GetProductClassesRequest request,
            ServerCallContext context)
        {
            var productClasses = await _db.ProductClasses.ToListAsync(context.CancellationToken);
            var results = _mapper.Map<GetProductClassesResponse>(productClasses);
            return results;
        }

        public override Task<GetProductClassResponse> GetProductClass(GetProductClassRequest request,
            ServerCallContext context)
        {
            return base.GetProductClass(request, context);
        }

        public override Task<IsProductClassIsAncestorResponse> IsProductClassIsAncestor(
            IsProductClassIsAncestorRequest request, ServerCallContext context)
        {
            return base.IsProductClassIsAncestor(request, context);
        }
    }
}