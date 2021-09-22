using System.Threading.Tasks;
using DubGrpc.RunnableProcesses;
using Grpc.Core;

namespace Dub.Grpc
{
    public class
        RunnableProcessService : RunnableProcessesService.RunnableProcessesServiceBase
    {
        public override Task<AddRunnableProcessResponse> AddRunnableProcess(AddRunnableProcessRequest request,
            ServerCallContext context)
        {
            return base.AddRunnableProcess(request, context);
        }

        public override Task<GetRunnableProcessResponse> GetRunnableProcessStep(GetRunnableProcessRequest request,
            ServerCallContext context)
        {
            return base.GetRunnableProcessStep(request, context);
        }

        public override Task<GetRunnableProcessesResponse> GetRunnableProcessSteps(GetRunnableProcessesRequest request,
            ServerCallContext context)
        {
            return base.GetRunnableProcessSteps(request, context);
        }
    }
}