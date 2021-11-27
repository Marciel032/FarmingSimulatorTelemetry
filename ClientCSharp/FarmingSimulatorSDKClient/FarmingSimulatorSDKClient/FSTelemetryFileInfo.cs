using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace FarmingSimulatorSDKClient
{
    public enum FSFileType: short { 
        VehicleStatic,
        VehicleDynamic,
        Game
    }

    public class FSTelemetryFileInfo
    {
        public string FilePah { get; set; }
        public DateTime LastRead { get; set; } = DateTime.MinValue;

        public FSTelemetryFileInfo(string filePath)
        {
            FilePah = filePath;
        }
    }
}
