using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace FarmingSimulatorSDKClient
{
    public class FSTelemetry
    {
        public string Name { get; set; }
        public decimal Wear { get; set; }
        //TODO - convert this to timestamp, current value is miliseconds
        public long OperationTime { get; set; }
        public int Speed { get; set; }
        public decimal FuelMax { get; set; }
        public decimal Fuel { get; set; }
        public int RPMMax { get; set; }
        public int RPM { get; set; }
        public bool IsEngineStarted { get; set; }
        public int Gear { get; set; }
        public bool IsLightOn { get; set; }
        public bool IsHighLightOn { get; set; }
        public bool IsLightTurnRightOn { get; set; }
        public bool IsLightTurnLeftOn { get; set; }
        public bool IsLightHazardOn { get; set; }
        public bool IsWiperOn { get; set; }
    }
}
