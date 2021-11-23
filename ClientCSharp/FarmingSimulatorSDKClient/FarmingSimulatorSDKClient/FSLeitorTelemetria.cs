using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace FarmingSimulatorSDKClient
{
    public class FSLeitorTelemetria
    {
        private string caminhoArquivo = @"D:\Programas\Jogos\FarmingSimulator19\telemetria.ast";
        public bool ObterTelemetria(out FSTelemetria telemetria) {
            telemetria = new FSTelemetria();

            try
            {
                if (!ObterConteudoArquivo(out var conteudo))
                    return false;

                ProcessarTelemetria(telemetria, conteudo);
            }
            catch (Exception ex)
            {
                Console.WriteLine(ex.Message);
                return false;
            }

            return true;
        }

        private bool ObterConteudoArquivo(out string conteudo) {
            conteudo = string.Empty;
            if (!File.Exists(caminhoArquivo))
                return false;

            using (var fileReader = File.Open(caminhoArquivo, FileMode.Open, FileAccess.Read, FileShare.Write))
            {
                using (var stringReader = new StreamReader(fileReader, Encoding.UTF8))
                {
                    conteudo = stringReader.ReadToEnd();
                    return true;
                }
            }
        }

        private void ProcessarTelemetria(FSTelemetria telemetria, string conteudo) {
            var conteudos = conteudo.Split(new string[] { "|#|" }, StringSplitOptions.RemoveEmptyEntries);
            if (conteudos.Length < 16)
                return;

            telemetria.Nome = conteudos[0];
            telemetria.Dano = ConverterDecimal(conteudos[1]);
            telemetria.TempoOperacao = ConverterLong(conteudos[2]);
            telemetria.Velocidade = ConverterInteiro(conteudos[3]);
            telemetria.CapacidadeCombustivel = ConverterDecimal(conteudos[4]);
            telemetria.QuantidadeCombustivel = ConverterDecimal(conteudos[5]);
            telemetria.RotacaoMotorMaxima = ConverterInteiro(conteudos[6]);
            telemetria.RotacaoMotor = ConverterInteiro(conteudos[7]);
            telemetria.MotorLigado = ConverterBooleano(conteudos[8]);
            telemetria.Marcha = ConverterInteiro(conteudos[9]);
            telemetria.LuzLigada = ConverterBooleano(conteudos[10]);
            telemetria.LuzAltaLigada = ConverterBooleano(conteudos[11]);
            telemetria.SetaDireitaLigada = ConverterBooleano(conteudos[12]);
            telemetria.SetaEsquerdaLigada = ConverterBooleano(conteudos[13]);
            telemetria.AlertaLigado = ConverterBooleano(conteudos[14]);
            telemetria.LimpadorLigado = ConverterBooleano(conteudos[15]);
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
    }
}
