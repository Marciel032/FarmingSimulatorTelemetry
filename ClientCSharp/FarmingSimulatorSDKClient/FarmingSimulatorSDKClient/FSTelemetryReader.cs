using System;
using System.Globalization;
using System.IO;
using System.Text;
using System.Timers;

namespace FarmingSimulatorSDKClient
{
    public delegate void OnTelemetryRead(FSTelemetry telemetry);
    public class FSTelemetryReader
    {
        private readonly string dynamicFilePath;
        private readonly string staticFilePath;      
        private Timer timer;
        private DateTime lastWriteStaticFile = DateTime.MinValue;
        private DateTime lastWriteDynamicFile = DateTime.MinValue;
        private FSTelemetry telemetry;
        private bool timerEnabled;

        public event OnTelemetryRead OnTelemetryRead;

        public FSTelemetryReader(string pathMainExecutable)
        {
            var pathFiles = GetMainDirectory(pathMainExecutable);
            dynamicFilePath = Path.Combine(pathFiles, "dynamicTelemetry.sim");
            staticFilePath = Path.Combine(pathFiles, "staticTelemetry.sim");

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
                if (!ProcessDynamicTelemetry(telemetry, out var hasChangesDynamic))
                    return;

                if (!ProcessStaticTelemetry(telemetry, out var hasChangesStatic))
                    return;

                if(hasChangesDynamic || hasChangesStatic)
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

        private bool GetFileContent(string fileName, out string content) {
            content = string.Empty;
            if (!File.Exists(fileName))
                return false;

            using (var fileReader = File.Open(fileName, FileMode.Open, FileAccess.Read, FileShare.Write))
            {
                using (var stringReader = new StreamReader(fileReader, Encoding.UTF8))
                {
                    if (stringReader.EndOfStream)
                        return false;

                    content = stringReader.ReadToEnd();
                    return true;
                }
            }
        }

        private bool ProcessDynamicTelemetry(FSTelemetry telemetria, out bool hasChanges) {
            hasChanges = false;
            if (!File.Exists(dynamicFilePath))
                return false;

            var writeTime = File.GetLastWriteTime(dynamicFilePath);
            if (writeTime <= lastWriteDynamicFile) //File was not changed after las read, so, telemetry have same data
                return true;

            hasChanges = true;

            if (!GetFileContent(dynamicFilePath, out var dynamicContent))
                return false;

            var contents = dynamicContent.Split(';');
            if (contents.Length < 17)
                return false;

            telemetria.Wear = ConvertDecimal(contents[0]);
            telemetria.OperationTime = ConvertLong(contents[1]);
            telemetria.Speed = ConvertInteger(contents[2]);
            telemetria.Fuel = ConvertDecimal(contents[3]);
            telemetria.RPM = ConvertInteger(contents[4]);
            telemetria.IsEngineStarted = ConvertBoolean(contents[5]);
            telemetria.Gear = ConvertInteger(contents[6]);
            telemetria.IsLightOn = ConvertBoolean(contents[7]);
            telemetria.IsHighLightOn = ConvertBoolean(contents[8]);
            telemetria.IsLightTurnRightOn = ConvertBoolean(contents[9]);
            telemetria.IsLightTurnLeftOn = ConvertBoolean(contents[10]);
            telemetria.IsLightHazardOn = ConvertBoolean(contents[11]);
            telemetria.IsWiperOn = ConvertBoolean(contents[12]);
            telemetria.IsCruiseControlOn = ConvertBoolean(contents[13]);
            telemetria.CruiseControlSpeed = ConvertInteger(contents[14]);
            telemetria.IsHandBreakeOn = ConvertBoolean(contents[15]);

            lastWriteDynamicFile = writeTime;            
            return true;
        }

        private bool ProcessStaticTelemetry(FSTelemetry telemetria, out bool hasChanges)
        {
            hasChanges = false;
            if (!File.Exists(staticFilePath))
                return false;

            var writeTime = File.GetLastWriteTime(staticFilePath);
            if (writeTime <= lastWriteStaticFile) //File was not changed after las read, so, telemetry have same data
                return true;

            hasChanges = true;

            if (!GetFileContent(staticFilePath, out var dynamicContent))
                return false;

            var contents = dynamicContent.Split(';');
            if (contents.Length < 5)
                return false;

            telemetria.Name = contents[0];
            telemetria.FuelMax = ConvertDecimal(contents[1]);
            telemetria.RPMMax = ConvertInteger(contents[2]);
            telemetria.CruiseControlMaxSpeed = ConvertInteger(contents[3]);

            lastWriteStaticFile = writeTime;
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
