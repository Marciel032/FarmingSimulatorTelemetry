using FarmingSimulatorSDKClient;
using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace FarmingSimulatorTelemetria.Demo
{
    public partial class FarmingSimulatorTelemetry : Form
    {
        private  FSTelemetryReader telemetryReader;
        public FarmingSimulatorTelemetry()
        {
            InitializeComponent();
        }

        private void TelemetryReader_OnTelemetryRead(FSTelemetry telemetry)
        {
            var texto = JsonConvert.SerializeObject(telemetry, Formatting.Indented);
            richTextBox1.BeginInvoke((MethodInvoker)delegate ()
            {
                richTextBox1.Text = texto;
            });
        }

        private void buttonStart_Click(object sender, EventArgs e)
        {
            if (!Directory.Exists(textBoxFSDirectory.Text))
            {
                MessageBox.Show("Directory not exist.");
                return;
            }

            telemetryReader = new FSTelemetryReader(textBoxFSDirectory.Text);
            telemetryReader.OnTelemetryRead += TelemetryReader_OnTelemetryRead;
            telemetryReader.Start();
        }

        private void buttonStop_Click(object sender, EventArgs e)
        {
            telemetryReader?.Stop();
        }
    }
}
