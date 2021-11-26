FSTelemetry = {};

local updateInterval = {
	vehicle = 300,
	vechicleCurrent = 0,
	game = 1000,
	gameCurrent = 1000
}

local drivingVehicleLastState = false;

local vehicleDynamicTelemetry = {}
local vehicleStaticTelemetry = {}
local gameTelemetry = {}

local dynamicVehicleTelemetrySaved = {}
local staticVehicleTelemetrySaved = {}
local gameTelemetrySaved = {}

FSTelemetry:ClearVehicleTelemetry();
FSTelemetry:ClearGameTelemetry();

function FSTelemetry:update(dt)
	updateInterval.vechicleCurrent = updateInterval.vechicleCurrent + dt;	
	if updateInterval.vechicleCurrent >= updateInterval.vechicle then
		updateInterval.vechicleCurrent = 0;

		local drivingVehicle = FSTelemetry:IsDrivingVehicle();
		if drivingVehicle then
			FSTelemetry:ProcessVehicleData();
			FSTelemetry:WriteVehicleDynamicFile();
			FSTelemetry:WriteVehicleStaticFile();
		else
			-- Just write file a sigle time when player get out vehicle
			if drivingVehicleLastState then
				FSTelemetry:ClearVehicleTelemetry();
				FSTelemetry:WriteVehicleDynamicFile();
				FSTelemetry:WriteVehicleStaticFile();
			end
		end;

		drivingVehicleLastState = drivingVehicle;
		--print(DebugUtil.printTableRecursively(g_currentMission.controlledVehicle,".",0,5));
	end;

	updateInterval.gameCurrent = updateInterval.gameCurrent + dt;
	if updateInterval.gameCurrent >= updateInterval.game then
		updateInterval.gameCurrent = 0;

		FSTelemetry:ProcessGameData();
		FSTelemetry:WriteGameFile();
	end;
end

function FSTelemetry:IsDrivingVehicle()
	local vehicle = g_currentMission.controlledVehicle;
	local hasVehicle = vehicle ~= nil;
	return hasVehicle and vehicle.spec_motorized ~= nil;
	--TODO - Check vehicle is driving by IA
end

function FSTelemetry:ProcessVehicleData()
	local vehicle = g_currentMission.controlledVehicle;

	local specMotorized = vehicle.spec_motorized;
	if specMotorized ~= nil then
		vehicleDynamicTelemetry.IsMotorStarted = specMotorized.isMotorStarted;		
		--specMotorized.motorFan.enabled
		--specMotorized.motorTemperature.value
	end;

	vehicleStaticTelemetry.Name = vehicle:getName();
	if vehicle.getWearTotalAmount ~= nil and vehicle:getWearTotalAmount() ~= nil then
		vehicleDynamicTelemetry.Wear = vehicle:getWearTotalAmount();
	end;

	if vehicle.operatingTime ~= nil then
		vehicleDynamicTelemetry.OperationTimeMinutes = vehicle.operatingTime / (1000 * 60);
	end;

	local lastSpeed = math.max(0, vehicle:getLastSpeed() * vehicle.spec_motorized.speedDisplayScale)
	vehicleDynamicTelemetry.Speed = math.floor(lastSpeed);
	if math.abs(lastSpeed-vehicleDynamicTelemetry.Speed) > 0.5 then
		vehicleDynamicTelemetry.Speed = vehicleDynamicTelemetry.Speed + 1;
	end

	--TODO: GET CURRENT FILL TYPE
	local fuelFillType = vehicle:getConsumerFillUnitIndex(FillType.DIESEL)
	if vehicle.getFillUnitCapacity ~= nil then
		vehicleStaticTelemetry.FuelMax = vehicle:getFillUnitCapacity(fuelFillType);
	end;

	if vehicle.getFillUnitFillLevel ~= nil then
		vehicleDynamicTelemetry.Fuel = vehicle:getFillUnitFillLevel(fuelFillType);
	end;

	local motor = vehicle:getMotor();
	if motor ~= nil then	
		if motor.getMaxRpm ~= nil then
			vehicleStaticTelemetry.RPMMax = math.ceil(motor:getMaxRpm());
		end	
		if motor.getLastRealMotorRpm ~= nil and vehicleDynamicTelemetry.IsMotorStarted then
			vehicleDynamicTelemetry.RPM = math.ceil(motor:getLastRealMotorRpm());
		end		
		vehicleDynamicTelemetry.Gear = motor.gear;
	end;

	local specLights = vehicle.spec_lights;
	if specLights ~= nil then
		if specLights.turnLightState ~= nil then
			local state = specLights.turnLightState;
			vehicleDynamicTelemetry.IsLightTurnRightOn = state	== Lights.TURNLIGHT_RIGHT;
			vehicleDynamicTelemetry.IsLightTurnLeftOn = state == Lights.TURNLIGHT_LEFT;
			vehicleDynamicTelemetry.IsLightHazardOn = state == Lights.TURNLIGHT_HAZARD;

			--TODO: CALCULATE TURN LIGHT BLINK
			--local alpha = MathUtil.clamp((math.cos(7*getShaderTimeSec()) + 0.2), 0, 1)
		end;


		--0 - LIGHT				
		--1 - TURN LIGHT
		--2 - FRONTAL LIGHT
		--3 - HIGH LIGHT
		if specLights.lightsTypesMask ~= nil then
			vehicleDynamicTelemetry.IsLightOn = bitAND(specLights.lightsTypesMask, 2^0) ~= 0;
			vehicleDynamicTelemetry.IsLightHighOn = bitAND(specLights.lightsTypesMask, 2^3) ~= 0;
		end;
	end;

	local specWipers = vehicle.spec_wipers;
	if specWipers ~= nil and specWipers.hasWipers and vehicleDynamicTelemetry.IsMotorStarted then
		local rainScale = g_currentMission.environment.weather:getRainFallScale();
		if rainScale > 0 then
			for _, wiper in pairs(specWipers.wipers) do
				for stateIndex,state in ipairs(wiper.states) do
					if rainScale <= state.maxRainValue then
						vehicleDynamicTelemetry.IsWipersOn = true;
						break
					end
				end
				if vehicleDynamicTelemetry.IsWipersOn then
					break;
				end
			end
		end
	end;

	local specDrivable = vehicle.spec_drivable;
	if specDrivable ~= nil then
		--Drivable.CRUISECONTROL_STATE_OFF
		--Drivable.CRUISECONTROL_STATE_ACTIVE
		--Drivable.CRUISECONTROL_STATE_FULL
		vehicleDynamicTelemetry.IsCruiseControlOn = specDrivable.cruiseControl.state ~= Drivable.CRUISECONTROL_STATE_OFF;
		vehicleDynamicTelemetry.CruiseControlSpeed = specDrivable.cruiseControl.speed;
		vehicleStaticTelemetry.CruiseControlMaxSpeed = specDrivable.cruiseControl.maxSpeed;

		vehicleDynamicTelemetry.IsHandBrakeOn = specDrivable.doHandbrake;
	end
end

function FSTelemetry:ProcessGameData()
	if g_currentMission.player ~= nil then
        local farm = g_farmManager:getFarmById(g_currentMission.player.farmId)
		if farm ~= nil then
			gameTelemetry.Money = farm.money;
		end
    end

	if g_currentMission.environment ~= nil then
		local environment = g_currentMission.environment;
		if environment.weather ~= nil then
			local minTemp, maxTemp = environment.weather:getCurrentMinMaxTemperatures();
			gameTelemetry.TemperatureMin = minTemp;
			gameTelemetry.TemperatureMax = maxTemp;
			gameTelemetry.TempetatureTrend = environment.weather:getCurrentTemperatureTrend();
		end

		gameTelemetry.DayTimeMinutes = environment.dayTime / (1000 * 60);

		local sixHours = 6 * 60 * 60 * 1000
		local dayPlus6h, timePlus6h = environment:getDayAndDayTime(environment.dayTime + sixHours, environment.currentDay)
		gameTelemetry.WeatherCurrent = environment.weather:getWeatherTypeAtTime(environment.currentDay, environment.dayTime)
		gameTelemetry.WeatherNext = environment.weather:getWeatherTypeAtTime(dayPlus6h, timePlus6h)
	end
end

function FSTelemetry:ClearVehicleTelemetry()
	vehicleStaticTelemetry.Name = "";
	vehicleStaticTelemetry.FuelMax = 0.0;
	vehicleStaticTelemetry.RPMMax = 0;
	vehicleStaticTelemetry.CruiseControlMaxSpeed = 0;

	vehicleDynamicTelemetry.Wear = 0.0;
	vehicleDynamicTelemetry.OperationTimeMinutes = 0;
	vehicleDynamicTelemetry.Speed = 0;
	vehicleDynamicTelemetry.Fuel = 0.0;
	vehicleDynamicTelemetry.RPM = 0;
	vehicleDynamicTelemetry.IsMotorStarted = false;
	vehicleDynamicTelemetry.Gear = 0;
	vehicleDynamicTelemetry.IsLightOn = false;
	vehicleDynamicTelemetry.IsLightHighOn = false;
	vehicleDynamicTelemetry.IsLightTurnRightOn = false;
	vehicleDynamicTelemetry.IsLightTurnLeftOn = false;
	vehicleDynamicTelemetry.IsLightHazardOn = false;
	vehicleDynamicTelemetry.IsWipersOn = false;
	vehicleDynamicTelemetry.IsCruiseControlOn = false;
	vehicleDynamicTelemetry.CruiseControlSpeed = 0;
	vehicleDynamicTelemetry.IsHandBrakeOn = false;
end

function FSTelemetry:ClearGameTelemetry()
	gameTelemetry.Money = 0.0;
	gameTelemetry.TemperatureMin = 0.0;
	gameTelemetry.TemperatureMax = 0.0;
	gameTelemetry.TempetatureTrend = 0;
	gameTelemetry.DayTimeMinutes = 0;
	gameTelemetry.WeatherCurrent = 0;
	gameTelemetry.WeatherNext = 0;
end

function  FSTelemetry:BuildVehicleStaticText()
	local text = FSTelemetry:AddText(vehicleStaticTelemetry.Name, "");
	text = FSTelemetry:AddTextDecimal(vehicleStaticTelemetry.FuelMax, text);
	text = FSTelemetry:AddTextNumber(vehicleStaticTelemetry.RPMMax, text);
	text = FSTelemetry:AddTextNumber(vehicleStaticTelemetry.CruiseControlMaxSpeed, text);
	return text;
end 

function FSTelemetry:BuildVehicleDynamicText()
	local text = FSTelemetry:AddTextDecimal(vehicleDynamicTelemetry.Wear, "");
	text = FSTelemetry:AddTextNumber(vehicleDynamicTelemetry.OperationTimeMinutes, text);
	text = FSTelemetry:AddTextNumber(vehicleDynamicTelemetry.Speed, text);
	text = FSTelemetry:AddTextDecimal(vehicleDynamicTelemetry.Fuel, text);
	text = FSTelemetry:AddTextNumber(vehicleDynamicTelemetry.RPM, text);
	text = FSTelemetry:AddTextBoolean(vehicleDynamicTelemetry.IsMotorStarted, text);
	text = FSTelemetry:AddTextNumber(vehicleDynamicTelemetry.Gear, text);
	text = FSTelemetry:AddTextBoolean(vehicleDynamicTelemetry.IsLightOn, text);
	text = FSTelemetry:AddTextBoolean(vehicleDynamicTelemetry.IsLightHighOn, text);
	text = FSTelemetry:AddTextBoolean(vehicleDynamicTelemetry.IsLightTurnRightOn, text);
	text = FSTelemetry:AddTextBoolean(vehicleDynamicTelemetry.IsLightTurnLeftOn, text);
	text = FSTelemetry:AddTextBoolean(vehicleDynamicTelemetry.IsLightHazardOn, text);
	text = FSTelemetry:AddTextBoolean(vehicleDynamicTelemetry.IsWipersOn, text);
	text = FSTelemetry:AddTextBoolean(vehicleDynamicTelemetry.IsCruiseControlOn, text);
	text = FSTelemetry:AddTextNumber(vehicleDynamicTelemetry.CruiseControlSpeed, text);
	text = FSTelemetry:AddTextBoolean(vehicleDynamicTelemetry.IsHandBrakeOn, text);
	return text;
end

function FSTelemetry:BuildGameText()
	local text = FSTelemetry:AddTextDecimal(gameTelemetry.Money, "");
	text = FSTelemetry:AddTextDecimal(gameTelemetry.TemperatureMin, text);
	text = FSTelemetry:AddTextDecimal(gameTelemetry.TemperatureMax, text);
	text = FSTelemetry:AddTextNumber(gameTelemetry.TempetatureTrend, text);
	text = FSTelemetry:AddTextNumber(gameTelemetry.DayTimeMinutes, text);
	text = FSTelemetry:AddTextNumber(gameTelemetry.WeatherCurrent, text);
	text = FSTelemetry:AddTextNumber(gameTelemetry.WeatherNext, text);
	return text;
end

function FSTelemetry:CopyTable(table)
	local table2 = {}
	for key,value in pairs(table) do
		table2[key] = value
	end
	return table2
end

function FSTelemetry:TablesAreEquals(table1,table2,ignore_mt)
	local ty1 = type(table1)
	local ty2 = type(table2)
	if ty1 ~= ty2 then return false end
	if ty1 ~= 'table' and ty2 ~= 'table' then return table1 == table2 end
	local mt = getmetatable(table1)
	if not ignore_mt and mt and mt.__eq then return table1 == table2 end
	for k1,v1 in pairs(table1) do
		local v2 = table2[k1]
		if v2 == nil or not FSTelemetry:TablesAreEquals(v1,v2) then return false end
	end
	for k2,v2 in pairs(table2) do
		local v1 = table1[k2]
		if v1 == nil or not FSTelemetry:TablesAreEquals(v1,v2) then return false end
	end
	return true
end

function FSTelemetry:AddTextDecimal(value, text)
	local decimalText = string.format("%.2f", value);
	return FSTelemetry:AddText(decimalText, text);
end

function FSTelemetry:AddTextNumber(value, text)
	local numberText = string.format("%d", value);
	return FSTelemetry:AddText(numberText, text);
end

function FSTelemetry:AddTextBoolean(value, text)
	local textBoolean = value and "1" or "0";
	return FSTelemetry:AddText(textBoolean, text);
end

function FSTelemetry:AddText(value, text)
	return text .. value .. ";";
end

function FSTelemetry:WriteVehicleDynamicFile()
	if FSTelemetry:TablesAreEquals(vehicleDynamicTelemetry, dynamicVehicleTelemetrySaved) then
		return;
	end;

	local text = FSTelemetry:BuildVehicleDynamicText();
	if FSTelemetry:WriteFile("vehicleDynamicTelemetry.sim", text) then
		dynamicVehicleTelemetrySaved = FSTelemetry:CopyTable(vehicleDynamicTelemetry);
	end;
end

function FSTelemetry:WriteVehicleStaticFile()
	if FSTelemetry:TablesAreEquals(vehicleStaticTelemetry, staticVehicleTelemetrySaved) then
		return;
	end;

	local text = FSTelemetry:BuildVehicleStaticText();
	if FSTelemetry:WriteFile("vehicleStaticTelemetry.sim", text) then
		staticVehicleTelemetrySaved = FSTelemetry:CopyTable(vehicleStaticTelemetry);
	end;
end

function FSTelemetry:WriteGameFile()
	if FSTelemetry:TablesAreEquals(gameTelemetry, gameTelemetrySaved) then
		return;
	end;

	local text = FSTelemetry:BuildGameText();
	if FSTelemetry:WriteFile("gameTelemetry.sim", text) then
		gameTelemetrySaved = FSTelemetry:CopyTable(gameTelemetry);
	end;
end

function FSTelemetry:WriteFile(name, content)
	local file = io.open(name, "w");
	if file ~= nil then
		file:write(content);
		file:close();
		return true;
	end;
	return false;
end

addModEventListener(FSTelemetry);