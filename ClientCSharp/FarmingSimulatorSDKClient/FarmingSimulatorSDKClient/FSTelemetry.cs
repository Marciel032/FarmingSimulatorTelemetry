using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace FarmingSimulatorSDKClient
{
    public class FSTelemetry
    {
        public VehicleTelemetry Vehicle { get; set; }
        public GameTelemetry Game { get; set; }

        public FSTelemetry()
        {
            Vehicle = new VehicleTelemetry();
            Game = new GameTelemetry();
        }
    }

    public enum TemperatureTrendType : short {
        Rising = -1,
        Stavle = 0,
        Dropping = 1
    }

    public enum WeatherType : short
    {
        Sun = 1,
        Rain = 2,
        Cloud = 3
    }

    public class GameTelemetry
    {
        public decimal Money { get; set; }
        public decimal TemperatureMin { get; set; }
        public decimal TemperatureMax { get; set; }
        public TemperatureTrendType TemperatureTrend { get; set; }
        public int DayTimeMinutes { get; set; }
        public WeatherType WeatherCurrent { get; set; }
        public WeatherType WeatherNext { get; set; }
    }

    public class VehicleTelemetry
    {
        public string Name { get; set; }
        public decimal Wear { get; set; }
        //TODO - convert this to timestamp, current value is miliseconds
        public long OperationTimeMinutes { get; set; }
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
        public bool IsCruiseControlOn { get; set; }
        public int CruiseControlSpeed { get; set; }
        public int CruiseControlMaxSpeed { get; set; }
        public bool IsHandBreakeOn { get; set; }
    }
}
