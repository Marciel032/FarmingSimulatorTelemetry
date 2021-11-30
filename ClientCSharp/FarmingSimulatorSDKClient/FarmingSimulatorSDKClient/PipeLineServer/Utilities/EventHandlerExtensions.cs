using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace FarmingSimulatorSDKClient.PipeLineServer.Utilities
{
    public static class EventHandlerExtensions
    {
        public static void SafeInvoke<T>(this EventHandler<T> @event, object sender, T eventArgs) where T : EventArgs
        {
            if (@event != null)
            {
                @event(sender, eventArgs);
            }
        }
    }
}
