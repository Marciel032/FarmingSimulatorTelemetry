using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace FarmingSimulatorSDKClient.PipeLineServer.Interfaces
{
    internal interface ICommunication
    {
        void Start();

        void Stop();
    }
    
}
