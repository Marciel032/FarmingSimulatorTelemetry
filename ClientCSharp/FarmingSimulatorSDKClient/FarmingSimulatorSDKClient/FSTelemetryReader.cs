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
        private bool active;
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
            active = true;
        }

        public void Stop() {
            pipeServer.Stop();
            active = false;
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

                object convertedValue = ConvertToType(propertyInfo.PropertyType, values[i]);                

                if (convertedValue != null)
                    propertyInfo.SetValue(telemetry, convertedValue);
            }

            if(active)
                OnTelemetryRead?.Invoke(telemetry);
        }

        private object ConvertToType(Type type, string value) {
            if (type == typeof(decimal))
                return ConvertDecimal(value);
            else if (type == typeof(bool))
                return ConvertBoolean(value);
            else if (type == typeof(int))
                return ConvertInteger(value);
            else if (type == typeof(long))
                return ConvertLong(value);
            else if (type == typeof(string))
                return value;
            else if (type.IsEnum)
                return Enum.Parse(type, value);
            else if (type.IsArray)
                return ConvertArray(type, value);

            return null;
        }

        private decimal ConvertDecimal(string value) {
            if (decimal.TryParse(value, NumberStyles.Any, CultureInfo.GetCultureInfo("en-US"),  out var numero))
                return numero;

            return 0m;
        }

        private long ConvertLong(string value) {
            if (long.TryParse(value, out var resultado))
                return resultado;

            return 0;
        }

        private int ConvertInteger(string value)
        {
            if (int.TryParse(value, out var resultado))
                return resultado;

            return 0;
        }

        private bool ConvertBoolean(string value)
        {
            return value.Trim() == "1";
        }

        private Array ConvertArray(Type type, string value)
        {
            var elementType = type.GetElementType();
            var textValues = value.Split('¶');
            var array = Array.CreateInstance(elementType, textValues.Length - 1);
            for (int i = 0; i < textValues.Length - 1; i++)
            {
                array.SetValue(ConvertToType(elementType, textValues[i]), i);
            }

            return array;
        }
    }
}
