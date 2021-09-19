using System;
using System.Threading.Tasks;
using Dub.Core.Exceptions;
using Grpc.Core;
using Grpc.Core.Interceptors;

namespace Dub.Grpc.Interceptors
{
    public class GrpcExceptionInterceptor : Interceptor
    {
        public override async Task<TResponse> UnaryServerHandler<TRequest, TResponse>(TRequest request,
            ServerCallContext context,
            UnaryServerMethod<TRequest, TResponse> continuation)
        {
            try
            {
                return await base.UnaryServerHandler(request, context, continuation);
            }
            catch (DomainException ex)
            {
                var status = ex switch
                {
                    NotFoundException notFoundException => new Status(StatusCode.NotFound, notFoundException.Message),
                    _ => new Status(StatusCode.Internal, "Unknown exception.")
                };

                throw new RpcException(status);
            }
        }
    }
}