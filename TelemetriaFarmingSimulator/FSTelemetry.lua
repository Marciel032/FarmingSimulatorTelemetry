FSTelemetry = {}
FSContext = {	
	UpdateInterval = {
		Target = 16.66, --Restrict to 60 FPS. 16.66 = 1000ms / 60 frames
		Current = 0.0
	},
	PipeControl = {
		Pipe = nil,
		PipeName = "\\\\.\\pipe\\fssimx",
		RefreshRate = 300,
		RefreshCurrent = -1
	},
	Telemetry = {}
};

function FSTelemetry:ini()
	FSTelemetry:ClearGameTelemetry();
	FSTelemetry:ClearVehicleTelemetry();
	print("inicia")
end

function FSTelemetry:update(dt)
	FSContext.UpdateInterval.Current = FSContext.UpdateInterval.Current + dt;
	if FSContext.UpdateInterval.Current >= FSContext.UpdateInterval.Target then
		FSContext.UpdateInterval.Current = 0;

		FSTelemetry:RefreshPipe();
		if FSContext.PipeControl.Pipe ~= nil then
			FSContext.Telemetry.IsDrivingVehicle = FSTelemetry:IsDrivingVehicle();
			if FSContext.Telemetry.IsDrivingVehicle then
				FSTelemetry:ProcessVehicleData();
			else
				FSTelemetry:ClearVehicleTelemetry();
			end;

			FSTelemetry:ProcessGameData();
			FSTelemetry:WriteTelemetry();
		end;
		--print(DebugUtil.printTableRecursively(g_currentMission.controlledVehicle,".",0,5));
	end;
end

function FSTelemetry:ClearGameTelemetry()
	FSContext.Telemetry.Money = 0.0;
	FSContext.Telemetry.TemperatureMin = 0.0;
	FSContext.Telemetry.TemperatureMax = 0.0;
	FSContext.Telemetry.TempetatureTrend = 0;
	FSContext.Telemetry.DayTimeMinutes = 0;
	FSContext.Telemetry.WeatherCurrent = 0;
	FSContext.Telemetry.WeatherNext = 0;
	FSContext.Telemetry.Day = 0;
end

function FSTelemetry:ClearVehicleTelemetry()
	FSContext.Telemetry.VehicleName = "";
	FSContext.Telemetry.FuelMax = 0.0;
	FSContext.Telemetry.Fuel = 0.0;
	FSContext.Telemetry.RPMMin = 0;
	FSContext.Telemetry.RPMMax = 0;
	FSContext.Telemetry.RPM = 0;
	FSContext.Telemetry.IsDrivingVehicle = false;
	FSContext.Telemetry.IsAiActive = false;
	FSContext.Telemetry.Wear = 0.0;
	FSContext.Telemetry.OperationTimeMinutes = 0;
	FSContext.Telemetry.Speed = 0.0;
	FSContext.Telemetry.IsEngineStarted = false;
	FSContext.Telemetry.Gear = 0;
	FSContext.Telemetry.IsLightOn = false;
	FSContext.Telemetry.IsLightHighOn = false;
	FSContext.Telemetry.IsLightTurnRightEnabled = false;
	FSContext.Telemetry.IsLightTurnRightOn = false;
	FSContext.Telemetry.IsLightTurnLeftEnabled = false;
	FSContext.Telemetry.IsLightTurnLeftOn = false;
	FSContext.Telemetry.IsLightHazardOn = false;
	FSContext.Telemetry.IsLightBeaconOn = false;
	FSContext.Telemetry.IsWipersOn = false;
	FSContext.Telemetry.IsCruiseControlOn = false;
	FSContext.Telemetry.CruiseControlMaxSpeed = 0;
	FSContext.Telemetry.CruiseControlSpeed = 0;
	FSContext.Telemetry.IsHandBrakeOn = false;
	FSContext.Telemetry.IsReverseDriving = false;
	FSContext.Telemetry.IsMotorFanEnabled = false;
	FSContext.Telemetry.MotorTemperature = 0.0;
	FSContext.Telemetry.VehiclePrice = 0.0;
	FSContext.Telemetry.VehicleSellPrice = 0.0;
end

function FSTelemetry:IsDrivingVehicle()
	local vehicle = g_currentMission.controlledVehicle;
	local hasVehicle = vehicle ~= nil;
	return hasVehicle and vehicle.spec_motorized ~= nil;
end

function FSTelemetry:ProcessVehicleData()
	local mission = g_currentMission;
	local vehicle = mission.controlledVehicle;
	local motor = vehicle:getMotor();
	local specMotorized = vehicle.spec_motorized;
	local specDrivable = vehicle.spec_drivable;
	local specLights = vehicle.spec_lights;
	local specWipers = vehicle.spec_wipers;

	FSTelemetry:ProcessPrice(vehicle);
	FSTelemetry:ProcessMotorFanEnabled(specMotorized);
	FSTelemetry:ProcessMotorTemperature(specMotorized);
	FSTelemetry:ProcessSpeed(vehicle, specMotorized);
	FSTelemetry:ProcessGear(motor);
	FSTelemetry:ProcessRPM(motor);
	FSTelemetry:ProcessReverseDriving(vehicle, specMotorized);
	FSTelemetry:ProcessEngineStarted(specMotorized);
	FSTelemetry:ProcessVehicleName(mission);
	FSTelemetry:ProcessAiActive(vehicle);
	FSTelemetry:ProcessWear(vehicle);
	FSTelemetry:ProcessOperationTime(vehicle);
	FSTelemetry:ProcessFuelLevelAndCapacity(vehicle);
	FSTelemetry:ProcessCruiseControl(specDrivable);
	FSTelemetry:ProcessHandBrake(specDrivable);
	FSTelemetry:ProcessTurnLightsHazard(specLights);
	FSTelemetry:ProcessLightBeacon(specLights);
	FSTelemetry:ProcessLight(specLights);
	FSTelemetry:ProcessWiper(specWipers, mission);
end

function FSTelemetry:ProcessMotorFanEnabled(motorized)
	if motorized ~= nil and motorized.motorFan ~= nil then
		FSContext.Telemetry.IsMotorFanEnabled = motorized.motorFan.enabled;
	else
		FSContext.Telemetry.IsMotorFanEnabled = false;
	end;
end

function FSTelemetry:ProcessMotorTemperature(motorized)
	if motorized ~= nil and motorized.motorTemperature ~= nil then
		FSContext.Telemetry.MotorTemperature = motorized.motorTemperature.value;
	else
		FSContext.Telemetry.MotorTemperature = 0;
	end;
end

function FSTelemetry:ProcessSpeed(vehicle, motorized)
	if motorized ~= nil and vehicle.getLastSpeed ~= nil then
		FSContext.Telemetry.Speed = math.max(0.0, vehicle:getLastSpeed() * motorized.speedDisplayScale)
	else
		FSContext.Telemetry.Speed = 0;
	end;
end

function FSTelemetry:ProcessRPM(motor)
	if motor ~= nil then
		if motor.getMinRpm ~= nil then
			FSContext.Telemetry.RPMMin = math.ceil(motor:getMinRpm());
		else
			FSContext.Telemetry.RPMMin = 0;
		end	

		if motor.getMaxRpm ~= nil then
			FSContext.Telemetry.RPMMax = math.ceil(motor:getMaxRpm());
		else
			FSContext.Telemetry.RPMMax = 0;
		end

		if motor.getLastRealMotorRpm ~= nil then
			FSContext.Telemetry.RPM = math.ceil(motor:getLastRealMotorRpm());
		else
			FSContext.Telemetry.RPM = 0;
		end
	end;
end

function FSTelemetry:ProcessPrice(vehicle)
	if vehicle ~= nil then
		if vehicle.getPrice ~= nil then
			FSContext.Telemetry.VehiclePrice = vehicle:getPrice();
		else
			FSContext.Telemetry.VehiclePrice = 0.0;
		end

		if vehicle.getSellPrice ~= nil then
			FSContext.Telemetry.VehicleSellPrice = vehicle:getSellPrice();
		else
			FSContext.Telemetry.VehicleSellPrice = 0.0;
		end
	end;
end

function FSTelemetry:ProcessGear(motor)
	if motor ~= nil then
		FSContext.Telemetry.Gear = motor.gear;
	end;
end

function FSTelemetry:ProcessReverseDriving(vehicle, motorized)
	local reverserDirection = vehicle.getReverserDirection == nil and 1 or vehicle:getReverserDirection();
	FSContext.Telemetry.IsReverseDriving = vehicle:getLastSpeed() > motorized.reverseDriveThreshold and vehicle.movingDirection ~= reverserDirection;
end

function FSTelemetry:ProcessEngineStarted(motorized)
	FSContext.Telemetry.IsEngineStarted = motorized ~= nil and motorized.isMotorStarted;
end

function FSTelemetry:ProcessVehicleName(mission)
	FSContext.Telemetry.VehicleName = mission.currentVehicleName;
end

function FSTelemetry:ProcessAiActive(vehicle)
	FSContext.Telemetry.IsAiActive = vehicle.getIsAIActive ~= nil and vehicle:getIsAIActive();
end

function FSTelemetry:ProcessWear(vehicle)
	if vehicle.getWearTotalAmount ~= nil and vehicle:getWearTotalAmount() ~= nil then
		FSContext.Telemetry.Wear = vehicle:getWearTotalAmount();
	else
		FSContext.Telemetry.Wear = 0;
	end;
end

function FSTelemetry:ProcessOperationTime(vehicle)
	if vehicle.operatingTime ~= nil then
		FSContext.Telemetry.OperationTimeMinutes = math.floor(vehicle.operatingTime / (1000 * 60));
	else
		FSContext.Telemetry.OperationTimeMinutes = 0;
	end;
end

function FSTelemetry:ProcessFuelLevelAndCapacity(vehicle)
	--TODO: GET CURRENT FILL TYPE
	local fuelFillType = vehicle:getConsumerFillUnitIndex(FillType.DIESEL)
	if vehicle.getFillUnitCapacity ~= nil then
		FSContext.Telemetry.FuelMax = vehicle:getFillUnitCapacity(fuelFillType);
	else
		FSContext.Telemetry.FuelMax = 0;
	end;

	if vehicle.getFillUnitFillLevel ~= nil then
		FSContext.Telemetry.Fuel = vehicle:getFillUnitFillLevel(fuelFillType);
	else
		FSContext.Telemetry.Fuel = 0;
	end;
end

function FSTelemetry:ProcessCruiseControl(drivable)
	if drivable ~= nil then
		--Drivable.CRUISECONTROL_STATE_OFF
		--Drivable.CRUISECONTROL_STATE_ACTIVE
		--Drivable.CRUISECONTROL_STATE_FULL
		FSContext.Telemetry.IsCruiseControlOn = drivable.cruiseControl.state ~= Drivable.CRUISECONTROL_STATE_OFF;
		FSContext.Telemetry.CruiseControlSpeed = drivable.cruiseControl.speed;
		FSContext.Telemetry.CruiseControlMaxSpeed = drivable.cruiseControl.maxSpeed;
	else
		FSContext.Telemetry.IsCruiseControlOn = false;
		FSContext.Telemetry.CruiseControlSpeed = 0;
		FSContext.Telemetry.CruiseControlMaxSpeed = 0;
	end
end

--Aparently, it does'nt work
function FSTelemetry:ProcessHandBrake(drivable)
	if drivable ~= nil then
		FSContext.Telemetry.IsHandBrakeOn = drivable.doHandbrake;
	else
		FSContext.Telemetry.IsHandBrakeOn = false;
	end
end

function FSTelemetry:ProcessTurnLightsHazard(lights)
	if lights ~= nil and lights.turnLightState ~= nil then
		local state = lights.turnLightState;
		FSContext.Telemetry.IsLightTurnRightEnabled = state == Lights.TURNLIGHT_RIGHT;
		FSContext.Telemetry.IsLightTurnLeftEnabled = state == Lights.TURNLIGHT_LEFT;
		FSContext.Telemetry.IsLightHazardOn = state == Lights.TURNLIGHT_HAZARD;

		local alpha = MathUtil.clamp((math.cos(7 * getShaderTimeSec()) + 0.2), 0, 1)
		FSContext.Telemetry.IsLightTurnRightOn = (FSContext.Telemetry.IsLightTurnRightEnabled or FSContext.Telemetry.IsLightHazardOn) and alpha > 0.5;
		FSContext.Telemetry.IsLightTurnLeftOn = (FSContext.Telemetry.IsLightTurnLeftEnabled or FSContext.Telemetry.IsLightHazardOn) and alpha > 0.5;
	else
		FSContext.Telemetry.IsLightTurnRightEnabled = false;
		FSContext.Telemetry.IsLightTurnRightOn = false;
		FSContext.Telemetry.IsLightTurnLeftEnabled = false;
		FSContext.Telemetry.IsLightTurnLeftOn = false;
		FSContext.Telemetry.IsLightHazardOn = false;
	end;
end

function FSTelemetry:ProcessLightBeacon(lights)
	if lights ~= nil and lights.getBeaconLightsVisibility ~= nil then
		FSContext.Telemetry.IsLightBeaconOn = lights:getBeaconLightsVisibility();
	else
		FSContext.Telemetry.IsLightBeaconOn = false;
	end;
end

function FSTelemetry:ProcessLight(lights)
	if lights ~= nil and lights.lightsTypesMask ~= nil then
		--0 - LIGHT				
		--1 - TURN LIGHT
		--2 - FRONTAL LIGHT
		--3 - HIGH LIGHT

		FSContext.Telemetry.IsLightOn = bitAND(lights.lightsTypesMask, 2^0) ~= 0;
		FSContext.Telemetry.IsLightHighOn = bitAND(lights.lightsTypesMask, 2^3) ~= 0;
	else
		FSContext.Telemetry.IsLightOn = false;
		FSContext.Telemetry.IsLightHighOn = false;
	end;
end

function FSTelemetry:ProcessWiper(wipers, mission)
	FSContext.Telemetry.IsWipersOn = false;
	if wipers ~= nil and wipers.hasWipers then
		local rainScale = (mission.environment ~= nil and mission.environment.weather ~= nil and mission.environment.weather.getRainFallScale ~= nil) and mission.environment.weather:getRainFallScale() or 0;
		if rainScale > 0 then
			for _, wiper in pairs(wipers.wipers) do
				for stateIndex,state in ipairs(wiper.states) do
					if rainScale <= state.maxRainValue then
						FSContext.Telemetry.IsWipersOn = true;
						break
					end
				end
				if FSContext.Telemetry.IsWipersOn then
					break;
				end
			end
		end
	end;
end

function FSTelemetry:ProcessGameData()
	if g_currentMission.player ~= nil then
        local farm = g_farmManager:getFarmById(g_currentMission.player.farmId)
		if farm ~= nil then
			FSContext.Telemetry.Money = farm.money;
			--g_currentMission.mission.missionInfo.money
		end
    end

	if g_currentMission.environment ~= nil then
		local environment = g_currentMission.environment;
		if environment.weather ~= nil then
			local minTemp, maxTemp = environment.weather:getCurrentMinMaxTemperatures();
			FSContext.Telemetry.TemperatureMin = minTemp;
			FSContext.Telemetry.TemperatureMax = maxTemp;
			FSContext.Telemetry.TempetatureTrend = environment.weather:getCurrentTemperatureTrend();
		end

		FSContext.Telemetry.DayTimeMinutes = math.floor(environment.dayTime / (1000 * 60));

		local sixHours = 6 * 60 * 60 * 1000;
		local dayPlus6h, timePlus6h = environment:getDayAndDayTime(environment.dayTime + sixHours, environment.currentDay);
		FSContext.Telemetry.WeatherCurrent = environment.weather:getWeatherTypeAtTime(environment.currentDay, environment.dayTime);
		FSContext.Telemetry.WeatherNext = environment.weather:getWeatherTypeAtTime(dayPlus6h, timePlus6h);

		FSContext.Telemetry.Day = environment.currentDay;
	end
end

function  FSTelemetry:BuildHeaderText()
	local text = FSTelemetry:AddText("HEADER", "");
	for k, v in pairs(FSContext.Telemetry) do
		text = FSTelemetry:AddText(k, text);
	end
	return text;
end 

function FSTelemetry:BuildBodyText()
	local text = FSTelemetry:AddText("BODY", "");
	for key, value in pairs(FSContext.Telemetry) do
		local type = type(value);
		if type == "boolean" then
			text = FSTelemetry:AddTextBoolean(value, text);
		elseif type == "string" then
			text = FSTelemetry:AddText(value, text);
		elseif type =="number" then
			text = FSTelemetry:AddTextDecimal(value, text);
		end
	end
	return text;
end

function FSTelemetry:AddTextDecimal(value, text)
	local integerPart, floatPart = math.modf(value)	
	local numberText;
	if floatPart > 0 then
		numberText = string.format("%.2f", value);
	else
		numberText = string.format("%d", integerPart);
	end
	return FSTelemetry:AddText(numberText, text);
end

function FSTelemetry:AddTextBoolean(value, text)
	local textBoolean = value and "1" or "0";
	return FSTelemetry:AddText(textBoolean, text);
end

function FSTelemetry:AddText(value, text)
	return text .. value .. "§";
end

function FSTelemetry:WriteTelemetry()
	if FSContext.PipeControl.RefreshCurrent == 0 then
		FSContext.PipeControl.Pipe:write(FSTelemetry:BuildHeaderText());
		FSContext.PipeControl.Pipe:flush();
	end

	FSContext.PipeControl.Pipe:write(FSTelemetry:BuildBodyText());
	FSContext.PipeControl.Pipe:flush();
end

function FSTelemetry:RefreshPipe()
	FSContext.PipeControl.RefreshCurrent = FSContext.PipeControl.RefreshCurrent + 1;
	if FSContext.PipeControl.RefreshCurrent >= FSContext.PipeControl.RefreshRate then
		FSContext.PipeControl.RefreshCurrent = 0;
	end

	if FSContext.PipeControl.RefreshCurrent == 0 then
		if FSContext.PipeControl.Pipe ~= nil then
			FSContext.PipeControl.Pipe:flush();
			FSContext.PipeControl.Pipe:close();
		end

		FSContext.PipeControl.Pipe = io.open(FSContext.PipeControl.PipeName, "w");
	end	
end

addModEventListener(FSTelemetry);