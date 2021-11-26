FSTelemetry = {};

local refreshInterval = 300;
local currentRefreshInterval = 0;
local drivingVehicleLastState = false;

local dynamicVehicleTelemetry = {}
local staticVehicleTelemetry = {}

local dynamicVehicleTelemetrySaved = {}
local staticVehicleTelemetrySaved = {}

FSTelemetry:ClearTelemetry();

function FSTelemetry:update(dt)
	currentRefreshInterval = currentRefreshInterval + dt;
	if currentRefreshInterval >= refreshInterval then
		currentRefreshInterval = 0;

		local drivingVehicle = FSTelemetry:IsDrivingVehicle();
		if drivingVehicle then
			FSTelemetry:ProcessVehicleData();
			FSTelemetry:WriteDynamicFile();
			FSTelemetry:WriteStaticFile();
		else
			-- Just write file a sigle time when player get out vehicle
			if drivingVehicleLastState then
				FSTelemetry:ClearTelemetry();
				FSTelemetry:WriteDynamicFile();
				FSTelemetry:WriteStaticFile();
			end
		end;

		drivingVehicleLastState = drivingVehicle;
		--print(DebugUtil.printTableRecursively(g_currentMission.controlledVehicle,".",0,5));
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
		dynamicVehicleTelemetry.IsMotorStarted = specMotorized.isMotorStarted;		
		--specMotorized.motorFan.enabled
		--specMotorized.motorTemperature.value
	end;

	staticVehicleTelemetry.Name = vehicle:getName();
	if vehicle.getWearTotalAmount ~= nil and vehicle:getWearTotalAmount() ~= nil then
		dynamicVehicleTelemetry.Wear = vehicle:getWearTotalAmount();
	end;

	if vehicle.operatingTime ~= nil then
		dynamicVehicleTelemetry.OperationTime = vehicle.operatingTime;
	end;

	local lastSpeed = math.max(0, vehicle:getLastSpeed() * vehicle.spec_motorized.speedDisplayScale)
	dynamicVehicleTelemetry.Speed = math.floor(lastSpeed);
	if math.abs(lastSpeed-dynamicVehicleTelemetry.Speed) > 0.5 then
		dynamicVehicleTelemetry.Speed = dynamicVehicleTelemetry.Speed + 1;
	end

	--TODO: GET CURRENT FILL TYPE
	local fuelFillType = vehicle:getConsumerFillUnitIndex(FillType.DIESEL)
	if vehicle.getFillUnitCapacity ~= nil then
		staticVehicleTelemetry.FuelMax = vehicle:getFillUnitCapacity(fuelFillType);
	end;

	if vehicle.getFillUnitFillLevel ~= nil then
		dynamicVehicleTelemetry.Fuel = vehicle:getFillUnitFillLevel(fuelFillType);
	end;

	local motor = vehicle:getMotor();
	if motor ~= nil then	
		if motor.getMaxRpm ~= nil then
			staticVehicleTelemetry.RPMMax = math.ceil(motor:getMaxRpm());
		end	
		if motor.getLastRealMotorRpm ~= nil and dynamicVehicleTelemetry.IsMotorStarted then
			dynamicVehicleTelemetry.RPM = math.ceil(motor:getLastRealMotorRpm());
		end		
		dynamicVehicleTelemetry.Gear = motor.gear;
	end;

	local specLights = vehicle.spec_lights;
	if specLights ~= nil then
		if specLights.turnLightState ~= nil then
			local state = specLights.turnLightState;
			dynamicVehicleTelemetry.IsLightTurnRightOn = state	== Lights.TURNLIGHT_RIGHT;
			dynamicVehicleTelemetry.IsLightTurnLeftOn = state == Lights.TURNLIGHT_LEFT;
			dynamicVehicleTelemetry.IsLightHazardOn = state == Lights.TURNLIGHT_HAZARD;

			--TODO: CALCULATE TURN LIGHT BLINK
			--local alpha = MathUtil.clamp((math.cos(7*getShaderTimeSec()) + 0.2), 0, 1)
		end;


		--0 - LIGHT				
		--1 - TURN LIGHT
		--2 - FRONTAL LIGHT
		--3 - HIGH LIGHT
		if specLights.lightsTypesMask ~= nil then
			dynamicVehicleTelemetry.IsLightOn = bitAND(specLights.lightsTypesMask, 2^0) ~= 0;
			dynamicVehicleTelemetry.IsLightHighOn = bitAND(specLights.lightsTypesMask, 2^3) ~= 0;
		end;
	end;

	local specWipers = vehicle.spec_wipers;
	if specWipers ~= nil and specWipers.hasWipers and dynamicVehicleTelemetry.IsMotorStarted then
		local rainScale = g_currentMission.environment.weather:getRainFallScale();
		if rainScale > 0 then
			for _, wiper in pairs(specWipers.wipers) do
				for stateIndex,state in ipairs(wiper.states) do
					if rainScale <= state.maxRainValue then
						dynamicVehicleTelemetry.IsWipersOn = true;
						break
					end
				end
				if dynamicVehicleTelemetry.IsWipersOn then
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
		dynamicVehicleTelemetry.IsCruiseControlOn = specDrivable.cruiseControl.state ~= Drivable.CRUISECONTROL_STATE_OFF;
		dynamicVehicleTelemetry.CruiseControlSpeed = specDrivable.cruiseControl.speed;
		staticVehicleTelemetry.CruiseControlMaxSpeed = specDrivable.cruiseControl.maxSpeed;

		dynamicVehicleTelemetry.IsHandBrakeOn = specDrivable.doHandbrake;
	end
end

function FSTelemetry:ClearTelemetry()
	staticVehicleTelemetry.Name = "";
	staticVehicleTelemetry.FuelMax = 0.0;
	staticVehicleTelemetry.RPMMax = 0;
	staticVehicleTelemetry.CruiseControlMaxSpeed = 0;

	dynamicVehicleTelemetry.Wear = 0.0;
	dynamicVehicleTelemetry.OperationTime = 0;
	dynamicVehicleTelemetry.Speed = 0;
	dynamicVehicleTelemetry.Fuel = 0.0;
	dynamicVehicleTelemetry.RPM = 0;
	dynamicVehicleTelemetry.IsMotorStarted = false;
	dynamicVehicleTelemetry.Gear = 0;
	dynamicVehicleTelemetry.IsLightOn = false;
	dynamicVehicleTelemetry.IsLightHighOn = false;
	dynamicVehicleTelemetry.IsLightTurnRightOn = false;
	dynamicVehicleTelemetry.IsLightTurnLeftOn = false;
	dynamicVehicleTelemetry.IsLightHazardOn = false;
	dynamicVehicleTelemetry.IsWipersOn = false;
	dynamicVehicleTelemetry.IsCruiseControlOn = false;
	dynamicVehicleTelemetry.CruiseControlSpeed = 0;
	dynamicVehicleTelemetry.IsHandBrakeOn = false;
end

function  FSTelemetry:BuildStaticText()
	local text = FSTelemetry:AddText(staticVehicleTelemetry.Name, "");
	text = FSTelemetry:AddTextDecimal(staticVehicleTelemetry.FuelMax, text);
	text = FSTelemetry:AddTextNumber(staticVehicleTelemetry.RPMMax, text);
	text = FSTelemetry:AddTextNumber(staticVehicleTelemetry.CruiseControlMaxSpeed, text);
	return text;
end 

function FSTelemetry:BuildDynamicText()
	local text = FSTelemetry:AddTextDecimal(dynamicVehicleTelemetry.Wear, "");
	text = FSTelemetry:AddTextNumber(dynamicVehicleTelemetry.OperationTime, text);
	text = FSTelemetry:AddTextNumber(dynamicVehicleTelemetry.Speed, text);
	text = FSTelemetry:AddTextDecimal(dynamicVehicleTelemetry.Fuel, text);
	text = FSTelemetry:AddTextNumber(dynamicVehicleTelemetry.RPM, text);
	text = FSTelemetry:AddTextBoolean(dynamicVehicleTelemetry.IsMotorStarted, text);
	text = FSTelemetry:AddTextNumber(dynamicVehicleTelemetry.Gear, text);
	text = FSTelemetry:AddTextBoolean(dynamicVehicleTelemetry.IsLightOn, text);
	text = FSTelemetry:AddTextBoolean(dynamicVehicleTelemetry.IsLightHighOn, text);
	text = FSTelemetry:AddTextBoolean(dynamicVehicleTelemetry.IsLightTurnRightOn, text);
	text = FSTelemetry:AddTextBoolean(dynamicVehicleTelemetry.IsLightTurnLeftOn, text);
	text = FSTelemetry:AddTextBoolean(dynamicVehicleTelemetry.IsLightHazardOn, text);
	text = FSTelemetry:AddTextBoolean(dynamicVehicleTelemetry.IsWipersOn, text);
	text = FSTelemetry:AddTextBoolean(dynamicVehicleTelemetry.IsCruiseControlOn, text);
	text = FSTelemetry:AddTextNumber(dynamicVehicleTelemetry.CruiseControlSpeed, text);
	text = FSTelemetry:AddTextBoolean(dynamicVehicleTelemetry.IsHandBrakeOn, text);
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

function FSTelemetry:WriteDynamicFile()
	if FSTelemetry:TablesAreEquals(dynamicVehicleTelemetry, dynamicVehicleTelemetrySaved) then
		return;
	end;

	local text = FSTelemetry:BuildDynamicText();
	if FSTelemetry:WriteFile("dynamicTelemetry.sim", text) then
		dynamicVehicleTelemetrySaved = FSTelemetry:CopyTable(dynamicVehicleTelemetry);
	end;
end

function FSTelemetry:WriteStaticFile()
	if FSTelemetry:TablesAreEquals(staticVehicleTelemetry, staticVehicleTelemetrySaved) then
		return;
	end;

	local text = FSTelemetry:BuildStaticText();
	if FSTelemetry:WriteFile("staticTelemetry.sim", text) then
		staticVehicleTelemetrySaved = FSTelemetry:CopyTable(staticVehicleTelemetry);
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