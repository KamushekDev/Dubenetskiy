using System;

namespace Dub.Core.Exceptions
{
    public class NotFoundException : DomainException
    {
        public NotFoundException(Exception? innerException = null) : base("Entity not found", innerException) { }
    }
}