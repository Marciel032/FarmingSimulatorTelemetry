using FarmingSimulatorSDKClient.PipeLineServer;
using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.ComponentModel;
using System.Globalization;
using System.IO;
using System.Reflection;
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
        private Dictionary<string, PropertyInfo> telemetryProperties;
        private Dictionary<short, PropertyInfo> telemetryIndexes;
        public event OnTelemetryRead OnTelemetryRead;        

        public FSTelemetryReader()
        {
            telemetry = new FSTelemetry();
            InitializeTelemetryProperties();
            telemetryIndexes = new Dictionary<short, PropertyInfo>();
            pipeServer = new PipeServer("fssimx");
            pipeServer.MessageReceivedEvent += OnTelemetryReceived;
        }

        private void OnTelemetryReceived(object sender, PipeLineServer.Interfaces.MessageReceivedEventArgs e)
        {
            if (e.Message.StartsWith("HEADER"))
                ProcessTelemetryIndexes(e.Message);
            else
                ProcessTelemetry(e.Message);
        }

        public void Start() {
            pipeServer.Start();
        }

        public void Stop() {
            pipeServer.Stop();
        }

        private void InitializeTelemetryProperties() {
            telemetryProperties = new Dictionary<string, PropertyInfo>();
            var properties = telemetry.GetType().GetProperties(BindingFlags.Public | BindingFlags.Instance);
            foreach (var property in properties)
                telemetryProperties.Add(property.Name.ToLower(), property);
        }

        private void ProcessTelemetryIndexes(string headersText) {
            var headers = headersText.Split('§');            
            for (short i = 1; i < headers.Length - 1; i++)
            {
                if (!telemetryProperties.TryGetValue(headers[i].ToLower(), out var propertyInfo))
                    continue;


                if (!telemetryIndexes.ContainsKey(i))
                    telemetryIndexes.Add(i, propertyInfo);
                else
                    telemetryIndexes[i] = propertyInfo;
            }
        }

        private void ProcessTelemetry(string telemetryText) {
            var values = telemetryText.Split('§');
            for (short i = 1; i < values.Length - 1; i++)
            {
                if (!telemetryIndexes.TryGetValue(i, out var propertyInfo))
                    continue;

                object convertedValue = null;
                Type type = propertyInfo.PropertyType;
                if (type == typeof(decimal))
                    convertedValue = ConvertDecimal(values[i]);
                else if (type == typeof(bool))
                    convertedValue = ConvertBoolean(values[i]);
                else if (type == typeof(int))
                    convertedValue = ConvertInteger(values[i]);
                else if (type == typeof(long))
                    convertedValue = ConvertLong(values[i]);
                else if (type == typeof(string))
                    convertedValue = values[i];
                else if (type.IsEnum)
                    convertedValue = Enum.Parse(type, values[i]);

                if (convertedValue != null)
                    propertyInfo.SetValue(telemetry, convertedValue);
            }

            OnTelemetryRead?.Invoke(telemetry);
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
    }
}
