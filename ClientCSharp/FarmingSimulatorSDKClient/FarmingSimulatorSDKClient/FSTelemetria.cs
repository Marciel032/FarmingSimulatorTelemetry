using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace FarmingSimulatorSDKClient
{
    public class FSTelemetria
    {
        public string Nome { get; set; }
        public decimal Dano { get; set; }
        public long TempoOperacao { get; set; }
        public int Velocidade { get; set; }
        public decimal CapacidadeCombustivel { get; set; }
        public decimal QuantidadeCombustivel { get; set; }
        public int RotacaoMotorMaxima { get; set; }
        public int RotacaoMotor { get; set; }
        public bool MotorLigado { get; set; }
        public int Marcha { get; set; }
        public bool LuzLigada { get; set; }
        public bool LuzAltaLigada { get; set; }
        public bool SetaDireitaLigada { get; set; }
        public bool SetaEsquerdaLigada { get; set; }
        public bool AlertaLigado { get; set; }
        public bool LimpadorLigado { get; set; }
    }
}
