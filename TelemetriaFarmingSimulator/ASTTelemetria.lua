ASTTelemetria = {};

local tempoAtualizacao = 200;
local tempoAtualizacaoAtual = 0;

local telemetria = {}

function ASTTelemetria:update(dt)	
	tempoAtualizacaoAtual = tempoAtualizacaoAtual + dt;
	if tempoAtualizacaoAtual >= tempoAtualizacao then
		tempoAtualizacaoAtual = 0;

		ASTTelemetria:ZerarTelemetria();

		local veiculo = g_currentMission.controlledVehicle;
		local temVeiculo = veiculo ~= nil;
		local ehMotorizado = temVeiculo and veiculo.spec_motorized ~= nil;

		if temVeiculo and ehMotorizado then
			telemetria.Nome = veiculo:getName();
			if veiculo.getWearTotalAmount ~= nil and veiculo:getWearTotalAmount() ~= nil then
				telemetria.Dano = veiculo:getWearTotalAmount();
			end;

			if veiculo.operatingTime ~= nil then
				telemetria.TempoOperacao = veiculo.operatingTime;
			end;

			local ultimaVelocidade = math.max(0, veiculo:getLastSpeed() * veiculo.spec_motorized.speedDisplayScale)
			telemetria.Velocidade = math.floor(ultimaVelocidade);
			if math.abs(ultimaVelocidade-telemetria.Velocidade) > 0.5 then
				telemetria.Velocidade = telemetria.Velocidade + 1
			end

			--DESCOBRIR COMO OBTER O TIPO DE COMBUSTIVEL ATUAL
			local fuelFillType = veiculo:getConsumerFillUnitIndex(FillType.DIESEL)
			if veiculo.getFillUnitCapacity ~= nil then
				telemetria.CapacidadeCombustivel = veiculo:getFillUnitCapacity(fuelFillType);
			end;

			if veiculo.getFillUnitFillLevel ~= nil then
				telemetria.QuantidadeCombustivel = veiculo:getFillUnitFillLevel(fuelFillType);
			end;			

			local espec_motorizado = veiculo.spec_motorized;
			if espec_motorizado ~= nil then
				telemetria.MotorLigado = espec_motorizado.isMotorStarted;
			end;

			local motor = veiculo:getMotor();
			if motor ~= nil then	
				if motor.getMaxRpm ~= nil then
					telemetria.RotacaoMotorMaximo = math.ceil(motor:getMaxRpm());
				end	
				if motor.getLastRealMotorRpm ~= nil and telemetria.MotorLigado then
					telemetria.RotacaoMotor = math.ceil(motor:getLastRealMotorRpm());
				end		
				telemetria.Marcha = motor.gear;					
			end;

			local espec_luzes = veiculo.spec_lights;
			if espec_luzes ~= nil then
				if espec_luzes.turnLightState ~= nil then
					local estadoSetas = espec_luzes.turnLightState;
					telemetria.SetaDireita = estadoSetas	== Lights.TURNLIGHT_RIGHT;
					telemetria.SetaEsquerda = estadoSetas == Lights.TURNLIGHT_LEFT;
					telemetria.Alerta = estadoSetas == Lights.TURNLIGHT_HAZARD;

					--para calcular se a luz esta piscando ou apagada
					--local alpha = MathUtil.clamp((math.cos(7*getShaderTimeSec()) + 0.2), 0, 1)
				end;


				--0 - luz ligada				
				--1 - luz de trabalho trazeira ligada
				--2 - luz de trabalho frontal ligada
				--3 - luz alta ligada
				if espec_luzes.lightsTypesMask ~= nil then
					telemetria.Luz = bitAND(espec_luzes.lightsTypesMask, 2^0) ~= 0;
					telemetria.LuzAlta = bitAND(espec_luzes.lightsTypesMask, 2^3) ~= 0;
				end;
			end;			

			local spec_limpador = veiculo.spec_wipers;
			if spec_limpador ~= nil and spec_limpador.hasWipers and telemetria.MotorLigado then
				local escalaChuva = g_currentMission.environment.weather:getRainFallScale();
				if escalaChuva > 0 then
					for _, limpador in pairs(spec_limpador.wipers) do
						for stateIndex,state in ipairs(limpador.states) do
							if escalaChuva <= state.maxRainValue then
								telemetria.Limpador = true;
								break
							end
						end
						if telemetria.Limpador then
							break;
						end
					end
				end
			end;

			--print(DebugUtil.printTableRecursively(telemetria,".",0,1));

			--print(DebugUtil.printTableRecursively(g_currentMission.controlledVehicle,".",0,5));
		end;

		--g_currentModDirectory
		local file = io.open ("telemetria.ast", "w");
		if file ~= nil then
			file:write(ASTTelemetria:MontarTextoArquivo());
			file:close();
		end;
	end;	
end

function ASTTelemetria:ZerarTelemetria()
	telemetria.Nome = "";
	telemetria.Dano = 0.0;
	telemetria.TempoOperacao = 0;
	telemetria.Velocidade = 0;
	telemetria.CapacidadeCombustivel = 0.0;
	telemetria.QuantidadeCombustivel = 0.0;
	telemetria.RotacaoMotorMaximo = 0;
	telemetria.RotacaoMotor = 0;
	telemetria.MotorLigado = false;
	telemetria.Marcha = 0;
	telemetria.Luz = false;
	telemetria.LuzAlta = false;
	telemetria.SetaDireita = false;
	telemetria.SetaEsquerda = false;
	telemetria.Alerta = false;	
	telemetria.Limpador = false;
end

function ASTTelemetria:MontarTextoArquivo()
	local texto = ASTTelemetria:AdicionarTexto("", telemetria.Nome)
	texto = ASTTelemetria:AdicionarTexto(texto, ASTTelemetria:FormatarDecimal(telemetria.Dano));
	texto = ASTTelemetria:AdicionarTexto(texto, ASTTelemetria:FormatarNumero(telemetria.TempoOperacao));
	texto = ASTTelemetria:AdicionarTexto(texto, ASTTelemetria:FormatarNumero(telemetria.Velocidade));
	texto = ASTTelemetria:AdicionarTexto(texto, ASTTelemetria:FormatarDecimal(telemetria.CapacidadeCombustivel));
	texto = ASTTelemetria:AdicionarTexto(texto, ASTTelemetria:FormatarDecimal(telemetria.QuantidadeCombustivel));
	texto = ASTTelemetria:AdicionarTexto(texto, ASTTelemetria:FormatarNumero(telemetria.RotacaoMotorMaximo));
	texto = ASTTelemetria:AdicionarTexto(texto, ASTTelemetria:FormatarNumero(telemetria.RotacaoMotor));
	texto = ASTTelemetria:AdicionarTexto(texto, tostring(telemetria.MotorLigado));
	texto = ASTTelemetria:AdicionarTexto(texto, ASTTelemetria:FormatarNumero(telemetria.Marcha));
	texto = ASTTelemetria:AdicionarTexto(texto, tostring(telemetria.Luz));
	texto = ASTTelemetria:AdicionarTexto(texto, tostring(telemetria.LuzAlta));
	texto = ASTTelemetria:AdicionarTexto(texto, tostring(telemetria.SetaDireita));
	texto = ASTTelemetria:AdicionarTexto(texto, tostring(telemetria.SetaEsquerda));
	texto = ASTTelemetria:AdicionarTexto(texto, tostring(telemetria.Alerta));
	texto = ASTTelemetria:AdicionarTexto(texto, tostring(telemetria.Limpador));
	return texto;
end 

function ASTTelemetria:AdicionarTexto(texto, valor)
	return texto .. valor .. "|#|";
end

function ASTTelemetria:FormatarDecimal(valor)
	return string.format("%.2f", valor)
end

function ASTTelemetria:FormatarNumero(valor)
	return string.format("%d", valor)
end

addModEventListener(ASTTelemetria);