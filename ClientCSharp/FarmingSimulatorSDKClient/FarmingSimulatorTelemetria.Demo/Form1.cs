using FarmingSimulatorSDKClient;
using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace FarmingSimulatorTelemetria.Demo
{
    public partial class Form1 : Form
    {
        public Form1()
        {
            InitializeComponent();
            var telemetryReader = new FSTelemetryReader();
            telemetryReader.OnTelemetryRead += TelemetryReader_OnTelemetryRead;
            telemetryReader.Start();
        }

        private void TelemetryReader_OnTelemetryRead(FSTelemetry telemetry)
        {
            var texto = JsonConvert.SerializeObject(telemetry, Formatting.Indented);
            richTextBox1.BeginInvoke((MethodInvoker)delegate ()
            {
                richTextBox1.Text = texto;
            });
        }
    }
}
