using FarmingSimulatorSDKClient.PipeLineServer;
using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.ComponentModel;
using System.Globalization;
using System.IO;
using System.Text;
using System.Threading;
using System.Timers;

namespace FarmingSimulatorSDKClient
{
    public delegate void OnTelemetryRead(FSTelemetry telemetry);
    public class FSTelemetryReader
    {
        private FSTelemetry telemetry;
        private PipeServer pipeServer;
        public event OnTelemetryRead OnTelemetryRead;

        public FSTelemetryReader()
        {
            telemetry = new FSTelemetry();
            pipeServer = new PipeServer("fssimx");
            pipeServer.MessageReceivedEvent += OnTelemetryReceived;
        }

        private void OnTelemetryReceived(object sender, PipeLineServer.Interfaces.MessageReceivedEventArgs e)
        {
            throw new NotImplementedException();
        }

        public void Start() {
            pipeServer.Start();
        }

        public void Stop() {
            pipeServer.Stop();
        }


        /*
                private bool ReadGameTelemetry(GameTelemetry gameTelemetry, out bool hasChanges)
                {
                    if (!GetFileContent(FSFileType.Game, out var content, out hasChanges))
                        return false;

                    if (!hasChanges)
                        return true;

                    var contents = content.Split(';');
                    if (contents.Length < 8)
                        return false;

                    gameTelemetry.Money = ConvertDecimal(contents[0]);
                    gameTelemetry.TemperatureMin = ConvertDecimal(contents[1]);
                    gameTelemetry.TemperatureMax = ConvertDecimal(contents[2]);
                    gameTelemetry.TemperatureTrend = (TemperatureTrendType)ConvertInteger(contents[3]);
                    gameTelemetry.DayTimeMinutes = ConvertInteger(contents[4]);
                    gameTelemetry.WeatherCurrent = (WeatherType)ConvertInteger(contents[5]);
                    gameTelemetry.WeatherNext = (WeatherType)ConvertInteger(contents[6]);
                    return true;
                }

                private bool ProcessVehicleDynamicTelemetry(VehicleTelemetry vehicleTelemetry, out bool hasChanges) {
                    if (!GetFileContent(FSFileType.VehicleDynamic, out var content, out hasChanges))
                        return false;

                    if (!hasChanges)
                        return true;

                    var contents = content.Split(';');
                    if (contents.Length < 17)
                        return false;

                    vehicleTelemetry.Wear = ConvertDecimal(contents[0]);
                    vehicleTelemetry.OperationTimeMinutes = ConvertLong(contents[1]);
                    vehicleTelemetry.Speed = ConvertInteger(contents[2]);
                    vehicleTelemetry.Fuel = ConvertDecimal(contents[3]);
                    vehicleTelemetry.RPM = ConvertInteger(contents[4]);
                    vehicleTelemetry.IsEngineStarted = ConvertBoolean(contents[5]);
                    vehicleTelemetry.Gear = ConvertInteger(contents[6]);
                    vehicleTelemetry.IsLightOn = ConvertBoolean(contents[7]);
                    vehicleTelemetry.IsHighLightOn = ConvertBoolean(contents[8]);
                    vehicleTelemetry.IsLightTurnRightOn = ConvertBoolean(contents[9]);
                    vehicleTelemetry.IsLightTurnLeftOn = ConvertBoolean(contents[10]);
                    vehicleTelemetry.IsLightHazardOn = ConvertBoolean(contents[11]);
                    vehicleTelemetry.IsWiperOn = ConvertBoolean(contents[12]);
                    vehicleTelemetry.IsCruiseControlOn = ConvertBoolean(contents[13]);
                    vehicleTelemetry.CruiseControlSpeed = ConvertInteger(contents[14]);
                    vehicleTelemetry.IsHandBreakeOn = ConvertBoolean(contents[15]);          
                    return true;
                }

                private bool ProcessVehicleStaticTelemetry(VehicleTelemetry vehicleTelemetry, out bool hasChanges)
                {
                    if (!GetFileContent(FSFileType.VehicleStatic, out var content, out hasChanges))
                        return false;

                    if (!hasChanges)
                        return true;

                    var contents = content.Split(';');
                    if (contents.Length < 7)
                        return false;

                    vehicleTelemetry.Name = contents[0];
                    vehicleTelemetry.FuelMax = ConvertDecimal(contents[1]);
                    vehicleTelemetry.RPMMax = ConvertInteger(contents[2]);
                    vehicleTelemetry.CruiseControlMaxSpeed = ConvertInteger(contents[3]);
                    vehicleTelemetry.IsDrivingVehicle = ConvertBoolean(contents[4]);
                    vehicleTelemetry.IsAIActive = ConvertBoolean(contents[5]);

                    return true;
                }

                private decimal ConvertDecimal(string valor) {
                    if (decimal.TryParse(valor, NumberStyles.Any, CultureInfo.GetCultureInfo("en-US"),  out var numero))
                        return numero;

                    return 0m;
                }

                private long ConvertLong(string valor) {
                    if (long.TryParse(valor, out var resultado))
                        return resultado;

                    return 0;
                }

                private int ConvertInteger(string valor)
                {
                    if (int.TryParse(valor, out var resultado))
                        return resultado;

                    return 0;
                }

                private bool ConvertBoolean(string valor)
                {
                    return valor.Trim() == "1";
                }*/
    }
}
