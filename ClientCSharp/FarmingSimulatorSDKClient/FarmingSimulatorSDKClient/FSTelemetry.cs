using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace FarmingSimulatorSDKClient
{
    public class FSTelemetry
    {
        #region GameData
        public decimal Money { get; set; }
        public decimal TemperatureMin { get; set; }
        public decimal TemperatureMax { get; set; }
        public TemperatureTrendType TemperatureTrend { get; set; }
        public int DayTimeMinutes { get; set; }
        public WeatherType WeatherCurrent { get; set; }
        public WeatherType WeatherNext { get; set; }
        public int Day { get; set; }
        #endregion GameData

        #region VehicleData
        public string VehicleName { get; set; }
        public decimal Wear { get; set; }
        public long OperationTimeMinutes { get; set; }
        public decimal Speed { get; set; }
        public decimal FuelMax { get; set; }
        public decimal Fuel { get; set; }
        public int RPMMin { get; set; }
        public int RPMMax { get; set; }
        public int RPM { get; set; }
        public bool IsEngineStarted { get; set; }
        public int Gear { get; set; }
        public bool IsLightOn { get; set; }
        public bool IsLightHighOn { get; set; }
        public bool IsLightTurnRightEnabled { get; set; }
        public bool IsLightTurnRightOn { get; set; }
        public bool IsLightTurnLeftEnabled { get; set; }
        public bool IsLightTurnLeftOn { get; set; }
        public bool IsLightHazardOn { get; set; }
        public bool IsLightBeaconOn { get; set; }
        public bool IsWiperOn { get; set; }
        public bool IsCruiseControlOn { get; set; }
        public int CruiseControlSpeed { get; set; }
        public int CruiseControlMaxSpeed { get; set; }
        public bool IsHandBreakeOn { get; set; }
        public bool IsDrivingVehicle { get; set; }
        public bool IsAiActive { get; set; }
        public bool IsReverseDriving { get; set; }
        public bool IsMotorFanEnabled { get; set; }
        public decimal MotorTemperature { get; set; }
        public decimal VehiclePrice { get; set; }
        public decimal VehicleSellPrice { get; set; }
        #endregion
    }

    public enum TemperatureTrendType : short {
        Rising = -1,
        Stable = 0,
        Dropping = 1
    }

    public enum WeatherType : short
    {
        Sun = 1,
        Rain = 2,
        Cloud = 3,
        Snow = 4
    }
}
