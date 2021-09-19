using System.Threading.Tasks;
using AutoMapper;
using Dub.Core.Exceptions;
using Dub.Infrastructure.Database;
using Dub.Infrastructure.Database.Models;
using DubGrpc.Products;
using Grpc.Core;
using Microsoft.EntityFrameworkCore;

namespace Dub.Grpc
{
    public class ProductService : DubGrpc.Products.ProductService.ProductServiceBase
    {
        private readonly DubContext _db;
        private readonly IMapper _mapper;

        public ProductService(DubContext db, IMapper mapper)
        {
            _db = db;
            _mapper = mapper;
        }

        public override async Task<AddProductResponse> AddProduct(AddProductRequest request, ServerCallContext context)
        {
            var product = _mapper.Map<Product>(request);
            var result = await _db.AddAsync(product, context.CancellationToken);
            await _db.SaveChangesAsync();
            return new AddProductResponse
            {                                               
                Id = result.Entity.Id
            };
        }

        public override async Task<GetProductResponse> GetProduct(GetProductRequest request, ServerCallContext context)
        {
            var entity = await _db.Products.FindAsync();
            if (entity is null)
                throw new NotFoundException();
            return new GetProductResponse { Product = _mapper.Map<ProductMsg>(entity) };
        }

        public override async Task<GetProductsResponse> GetProducts(GetProductsRequest request,
            ServerCallContext context)
        {
            var products = await _db.Products.ToListAsync(context.CancellationToken);
            return _mapper.Map<GetProductsResponse>(products);
        }
    }
}