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
        }

        private void timer1_Tick(object sender, EventArgs e)
        {
            if (!new FSLeitorTelemetria().ObterTelemetria(out var telemetria))
                return;

            richTextBox1.Text = JsonConvert.SerializeObject(telemetria, Formatting.Indented);
        }
    }
}
