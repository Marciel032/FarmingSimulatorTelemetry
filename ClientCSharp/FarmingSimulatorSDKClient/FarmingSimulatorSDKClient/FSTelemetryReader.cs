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

            telemetria.Wear = ConverterDecimal(contents[0]);
            telemetria.OperationTime = ConverterLong(contents[1]);
            telemetria.Speed = ConverterInteiro(contents[2]);
            telemetria.Fuel = ConverterDecimal(contents[3]);
            telemetria.RPM = ConverterInteiro(contents[4]);
            telemetria.IsEngineStarted = ConverterBooleano(contents[5]);
            telemetria.Gear = ConverterInteiro(contents[6]);
            telemetria.IsLightOn = ConverterBooleano(contents[7]);
            telemetria.IsHighLightOn = ConverterBooleano(contents[8]);
            telemetria.IsLightTurnRightOn = ConverterBooleano(contents[9]);
            telemetria.IsLightTurnLeftOn = ConverterBooleano(contents[10]);
            telemetria.IsLightHazardOn = ConverterBooleano(contents[11]);
            telemetria.IsWiperOn = ConverterBooleano(contents[12]);
            telemetria.IsCruiseControlOn = ConverterBooleano(contents[13]);
            telemetria.CruiseControlSpeed = ConverterInteiro(contents[14]);
            telemetria.IsHandBreakeOn = ConverterBooleano(contents[15]);

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
            telemetria.FuelMax = ConverterDecimal(contents[1]);
            telemetria.RPMMax = ConverterInteiro(contents[2]);
            telemetria.CruiseControlMaxSpeed = ConverterInteiro(contents[3]);

            lastWriteStaticFile = writeTime;
            return true;
        }

        private decimal ConverterDecimal(string valor) {
            if (decimal.TryParse(valor, NumberStyles.Any, CultureInfo.GetCultureInfo("en-US"),  out var numero))
                return numero;

            return 0m;
        }

        private long ConverterLong(string valor) {
            if (long.TryParse(valor, out var resultado))
                return resultado;

            return 0;
        }

        private int ConverterInteiro(string valor)
        {
            if (int.TryParse(valor, out var resultado))
                return resultado;

            return 0;
        }

        private bool ConverterBooleano(string valor)
        {
            if (bool.TryParse(valor, out var resultado))
                return resultado;

            return false;
        }

        private string GetMainDirectory(string caminhoExecutavelPrincipal) {
            var directory = Path.GetDirectoryName(caminhoExecutavelPrincipal);
            if (directory.EndsWith("x64") || directory.EndsWith("x32"))
                directory = Path.GetDirectoryName(directory);
            return directory;
        }
    }
}
