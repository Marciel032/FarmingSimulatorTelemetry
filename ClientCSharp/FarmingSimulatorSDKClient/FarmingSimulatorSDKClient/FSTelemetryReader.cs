using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Text;
using System.Timers;

namespace FarmingSimulatorSDKClient
{
    public delegate void OnTelemetryRead(FSTelemetry telemetry);
    public class FSTelemetryReader
    {     
        private Timer timer;
        private Dictionary<FSFileType, FSTelemetryFileInfo> files;
        private FSTelemetry telemetry;
        private bool timerEnabled;

        public event OnTelemetryRead OnTelemetryRead;

        public FSTelemetryReader(string pathMainExecutable)
        {
            var pathFiles = GetMainDirectory(pathMainExecutable);
            files = new Dictionary<FSFileType, FSTelemetryFileInfo>();
            files.Add(FSFileType.VehicleStatic, new FSTelemetryFileInfo(Path.Combine(pathFiles, "vehicleStaticTelemetry.sim")));            
            files.Add(FSFileType.VehicleDynamic, new FSTelemetryFileInfo(Path.Combine(pathFiles, "vehicleDynamicTelemetry.sim")));            
            files.Add(FSFileType.Game, new FSTelemetryFileInfo(Path.Combine(pathFiles, "gameTelemetry.sim")));

            telemetry = new FSTelemetry();

            timerEnabled = false;
            timer = new Timer
            {
                Interval = 50,
                AutoReset = false                
            };
            timer.Elapsed += Timer_Elapsed;
        }

        private void Timer_Elapsed(object sender, ElapsedEventArgs e)
        {
            try
            {
                if (!ReadVehicleTelemetry(telemetry.Vehicle, out var hasVehicleChanges))
                    return;

                if (!ReadGameTelemetry(telemetry.Game, out var hasGameChanges))
                    return;

                if(hasVehicleChanges || hasGameChanges)
                    OnTelemetryRead?.Invoke(telemetry);
            }
            catch (Exception ex)
            {
                Console.WriteLine(ex.Message);
            }
            finally {
                timer.Enabled = timerEnabled;
            }
        }        

        public void Start() {
            timerEnabled = true;
            timer.Enabled = timerEnabled;
        }

        public void Stop() {
            timerEnabled = false;
            timer.Enabled = timerEnabled;
        }

        private bool ReadVehicleTelemetry(VehicleTelemetry vehicleTelemetry, out bool hasChanges) {
            hasChanges = false;
            if (!ProcessVehicleDynamicTelemetry(vehicleTelemetry, out var hasChangesDynamic))
                return false;

            if (!ProcessVehicleStaticTelemetry(vehicleTelemetry, out var hasChangesStatic))
                return false;

            hasChanges = hasChangesDynamic || hasChangesStatic;
            return true;
        }

        private bool ReadGameTelemetry(GameTelemetry gameTelemetry, out bool hasChanges)
        {
            if (!GetFileContent(FSFileType.Game, out var content, out hasChanges))
                return false;

            if (!hasChanges)
                return true;

            var contents = content.Split(';');
            if (contents.Length < 2)
                return false;

            gameTelemetry.Money = ConvertDecimal(contents[0]);
            return true;
        }

        private bool GetFileContent(FSFileType fileType, out string content, out bool hasChanges) {
            var fileInfo = files[fileType];

            hasChanges = false;
            content = string.Empty;

            if (!File.Exists(fileInfo.FilePah))
                return false;

            var writeTime = File.GetLastWriteTime(fileInfo.FilePah);
            if (writeTime <= fileInfo.LastRead) //File was not changed after last read, so, telemetry have same data
                return true;

            hasChanges = true;            

            using (var fileReader = File.Open(fileInfo.FilePah, FileMode.Open, FileAccess.Read, FileShare.Write))
            {
                using (var stringReader = new StreamReader(fileReader, Encoding.UTF8))
                {
                    if (stringReader.EndOfStream)
                        return false;

                    content = stringReader.ReadToEnd();
                    fileInfo.LastRead = writeTime;
                    return true;
                }
            }            
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
            vehicleTelemetry.OperationTime = ConvertLong(contents[1]);
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
            if (contents.Length < 5)
                return false;

            vehicleTelemetry.Name = contents[0];
            vehicleTelemetry.FuelMax = ConvertDecimal(contents[1]);
            vehicleTelemetry.RPMMax = ConvertInteger(contents[2]);
            vehicleTelemetry.CruiseControlMaxSpeed = ConvertInteger(contents[3]);

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
        }

        private string GetMainDirectory(string caminhoExecutavelPrincipal) {
            if(caminhoExecutavelPrincipal.EndsWith(".exe"))
                caminhoExecutavelPrincipal = Path.GetDirectoryName(caminhoExecutavelPrincipal);

            if (caminhoExecutavelPrincipal.EndsWith("x64") || caminhoExecutavelPrincipal.EndsWith("x32"))
                caminhoExecutavelPrincipal = Path.GetDirectoryName(caminhoExecutavelPrincipal);
            return caminhoExecutavelPrincipal;
        }
    }
}
