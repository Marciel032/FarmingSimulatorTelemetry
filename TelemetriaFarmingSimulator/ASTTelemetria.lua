ASTTelemetria = {};
addModEventListener(ASTTelemetria);

local tempoAtualizacao = 5000;
local tempoAtualizacaoAtual = 0;

function ASTTelemetria:update(dt)
	tempoAtualizacaoAtual = tempoAtualizacaoAtual + dt;
	if tempoAtualizacaoAtual >= tempoAtualizacao then
		tempoAtualizacaoAtual = 0;
		local veiculo = g_currentMission.controlledVehicle;
		local temVeiculo = veiculo ~= nil;
		local ehMotorizado = temVeiculo and veiculo.spec_motorized ~= nil;

		if temVeiculo and ehMotorizado then
			--DANO
			local dano = 0.0;
			if veiculo.getWearTotalAmount ~= nil and veiculo:getWearTotalAmount() ~= nil then
				dano = veiculo:getWearTotalAmount();
			end;

			--TEMPO OPERACAO
			local tempoOperacao = 0;
			if veiculo.operatingTime ~= nil then
				tempoOperacao = veiculo.operatingTime;
			end;

			--VELOCIDADE
			local ultimaVelocidade = math.max(0, veiculo:getLastSpeed() * veiculo.spec_motorized.speedDisplayScale)
			local velocidade = ultimaVelocidade;
			if velocidade < 0.5 then
				velocidade = 0
			end
			if math.abs(ultimaVelocidade-velocidade) > 0.5 then
				velocidade = velocidade + 1
			end

			local fuelFillType = veiculo:getConsumerFillUnitIndex(FillType.DIESEL)
			--CAPACIDADE TANQUE
			local capacidadeTanque = 0.0;
			if veiculo.getFillUnitCapacity ~= nil then
				capacidadeTanque = veiculo:getFillUnitCapacity(fuelFillType);
			end;

			--QUANTIDADE COMBUSTIVEL
			local quantidadeCombustivel = 0.0;
			if veiculo.getFillUnitFillLevel ~= nil then
				quantidadeCombustivel = veiculo:getFillUnitFillLevel(fuelFillType);
			end;

			print("Nome: " .. veiculo:getName());
			print("Velocidade: " .. velocidade);			
			print("Dano: " .. dano);
			print("Tempo operacao: " .. tempoOperacao);
			print("Quantidade combustivel: " .. tostring(quantidadeCombustivel));
			print("Capacidade combustivel: " .. tostring(capacidadeTanque));

			local motor = veiculo:getMotor();
			if motor ~= nil then				
				print("RPMMax: " .. string.format("%.d", motor:getMaxRpm()));
				print("RPM: " .. string.format("%.d", motor:getLastRealMotorRpm()));
				print("Marcha: " ..  motor.gear);				
			end;

			local motorizado = veiculo.spec_motorized;
			if motorizado ~= nil then
				print("Ligado: " .. tostring(motorizado.isMotorStarted));
			end;

			--print(DebugUtil.printTableRecursively(veiculo,".",0,1));

			--print(DebugUtil.printTableRecursively(g_currentMission.controlledVehicle,".",0,5));
		end;
	end;	
end
