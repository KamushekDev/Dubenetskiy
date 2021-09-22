using System.Threading.Tasks;
using AutoMapper;
using Dub.Core.Exceptions;
using Dub.Infrastructure.Database;
using Dub.Infrastructure.Database.Models;
using DubGrpc.ProductClasses;
using Grpc.Core;
using Microsoft.EntityFrameworkCore;

namespace Dub.Grpc
{
    public class ProductClassService : ProductClassesService.ProductClassesServiceBase
    {
        private readonly DubContext _db;
        private readonly IMapper _mapper;

        public ProductClassService(DubContext db, IMapper mapper)
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

        public override async Task<GetProductClassResponse> GetProductClass(GetProductClassRequest request,
            ServerCallContext context)
        {
            var id = request.Id;
            var entity = await _db.ProductClasses.FindAsync(id);
            if (entity is null)
                throw new NotFoundException();
            return _mapper.Map<GetProductClassResponse>(entity);
        }

        public override async Task<IsProductClassIsAncestorResponse> IsProductClassIsAncestor(
            IsProductClassIsAncestorRequest request, ServerCallContext context)
        {
            var ancestorId = request.AncestorId;
            var descendentId = request.DescendentId;
            bool isAncestor = false;
            var current = await _db.ProductClasses.FindAsync(descendentId);
            while (current is not null)
            {
                if (current.Id == ancestorId)
                {
                    isAncestor = true;
                    break;
                }

                current = current.ParentId is null
                    ? null
                    : await _db.ProductClasses.FindAsync(current.ParentId);
            }

            return new IsProductClassIsAncestorResponse { IsAncestor = isAncestor };
        }
    }
}