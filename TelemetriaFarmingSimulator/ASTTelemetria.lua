ASTTelemetria = {
	Nome = "",
	Dano = 0.0,
	TempoOperacao = 0,
	Velocidade = 0,
	CapacidadeCombustivel = 0.0,
	QuantidadeCombustivel = 0.0,
	RotacaoMotorMaximo = 0,
	RotacaoMotor = 0,
	MotorLigado = false,
	Marcha = 0,
	Luz = false,
	LuzAlta = false,
	SetaDireita = false,
	SetaEsquerda = false,
	Alerta = false,	
	Limpador = false
};

local tempoAtualizacao = 5000;
local tempoAtualizacaoAtual = 0;

function ASTTelemetria:update(dt)
	tempoAtualizacaoAtual = tempoAtualizacaoAtual + dt;
	if tempoAtualizacaoAtual >= tempoAtualizacao then
		tempoAtualizacaoAtual = 0;

		Nome = "";
		Dano = 0.0;
		TempoOperacao = 0;
		Velocidade = 0;
		CapacidadeCombustivel = 0.0;
		QuantidadeCombustivel = 0.0;
		RotacaoMotorMaximo = 0;
		RotacaoMotor = 0;
		MotorLigado = false;
		Marcha = 0;
		Luz = false;
		LuzAlta = false;
		SetaDireita = false;
		SetaEsquerda = false;
		Alerta = false;	
		Limpador = false;

		local veiculo = g_currentMission.controlledVehicle;
		local temVeiculo = veiculo ~= nil;
		local ehMotorizado = temVeiculo and veiculo.spec_motorized ~= nil;

		if temVeiculo and ehMotorizado then
			ASTTelemetria.Nome = veiculo:getName();
			if veiculo.getWearTotalAmount ~= nil and veiculo:getWearTotalAmount() ~= nil then
				ASTTelemetria.Dano = veiculo:getWearTotalAmount();
			end;

			if veiculo.operatingTime ~= nil then
				ASTTelemetria.TempoOperacao = veiculo.operatingTime;
			end;

			local ultimaVelocidade = math.max(0, veiculo:getLastSpeed() * veiculo.spec_motorized.speedDisplayScale)
			ASTTelemetria.Velocidade = ultimaVelocidade;
			if ASTTelemetria.Velocidade < 0.5 then
				ASTTelemetria.Velocidade = 0
			end
			if math.abs(ultimaVelocidade-ASTTelemetria.Velocidade) > 0.5 then
				ASTTelemetria.Velocidade = ASTTelemetria.Velocidade + 1
			end

			--DESCOBRIR COMO OBTER O TIPO DE COMBUSTIVEL ATUAL
			local fuelFillType = veiculo:getConsumerFillUnitIndex(FillType.DIESEL)
			if veiculo.getFillUnitCapacity ~= nil then
				ASTTelemetria.CapacidadeCombustivel = veiculo:getFillUnitCapacity(fuelFillType);
			end;

			if veiculo.getFillUnitFillLevel ~= nil then
				ASTTelemetria.QuantidadeCombustivel = veiculo:getFillUnitFillLevel(fuelFillType);
			end;

			local motor = veiculo:getMotor();
			if motor ~= nil then	
				if Motor.getMaxRpm ~= nil then
					ASTTelemetria.RotacaoMotorMaximo = math.ceil(motor:getMaxRpm());
				end	
				if Motor.getLastRealMotorRpm ~= nil then
					ASTTelemetria.RotacaoMotor = math.ceil(motor:getLastRealMotorRpm());
				end		
				ASTTelemetria.Marcha = motor.gear;					
			end;

			local espec_motorizado = veiculo.spec_motorized;
			if espec_motorizado ~= nil then
				ASTTelemetria.MotorLigado = espec_motorizado.isMotorStarted;
			end;

			local = espec_luzes = veiculo.spec_lights;
			if espec_luzes ~= nil then
				if espec_luzes.turnLightState ~= nil then
					local estadoSetas = espec_luzes.turnLightState;
					ASTTelemetria.SetaDireita = estadoSetas	== Lights.TURNLIGHT_RIGHT;
					ASTTelemetria.SetaEsquerda = estadoSetas == Lights.TURNLIGHT_LEFT;
					ASTTelemetria.Alerta = estadoSetas == Lights.TURNLIGHT_HAZARD;

					--para calcular se a luz esta piscando ou apagada
					--local alpha = MathUtil.clamp((math.cos(7*getShaderTimeSec()) + 0.2), 0, 1)
				end;


				--Descobrir como saber se a luz e luz alta estão ligadas
				--tipos de luzes parecem ser 0 1 2, sendo que 0 deve ser a luz baixa				
				if espec_luzes.lightsTypesMask ~= nil then
					--percore as luzes existentes
					--for _,light in pairs(light.lightTypes) do
					ASTTelemetria.Luz = bitAND(espec_luzes.lightsTypesMask, 2^0) ~= 0;
					ASTTelemetria.LuzAlta = bitAND(espec_luzes.lightsTypesMask, 2^1) ~= 0;
				end;
			end;			

			local spec_limpador = veiculo.spec_wipers;
			if spec_limpador ~= nil and spec_limpador.hasWipers and ASTTelemetria.MotorLigado then
				local escalaChuva = g_currentMission.environment.weather:getRainFallScale();
				if escalaChuva > 0 then
					for _, limpador in pairs(spec_limpador.wipers) do
						for stateIndex,state in ipairs(limpador.states) do
							if spec.lastRainScale <= state.maxRainValue then
								ASTTelemetria.Limpador = true;
								break
							end
						end
						if ASTTelemetria.Limpador then
							break;
						end
					end
				end
			end;

			print(DebugUtil.printTableRecursively(ASTTelemetria,".",0,1));

			--print(DebugUtil.printTableRecursively(g_currentMission.controlledVehicle,".",0,5));
		end;

		local textoArquivo = "";
		for _,v in pairs(obj) do
			textoArquivo = textoArquivo .. v .. "|#|";
        end

		local file = io.open ("telemetria.txt", "w+");
		file:write(textoArquivo);
		file:close();
	end;	
end

addModEventListener(ASTTelemetria);