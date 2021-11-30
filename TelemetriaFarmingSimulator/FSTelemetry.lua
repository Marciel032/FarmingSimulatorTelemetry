FSTelemetry = {	
	UpdateInterval = {
		Vehicle = 16.66, --Restrict to 60 FPS. 16.66 = 1000ms / 60 frames
		VehicleCurrent = 0.0
	},
	PipeControl = {
		Pipe = nil,
		PipeName = "\\\\.\\pipe\\fssimx",
		RefreshRate = 600, --Every 10 seconds
		RefreshCurrent = 0
	},
	Telemetry = {}
};

FSTelemetry:ClearGameTelemetry();
FSTelemetry:ClearVehicleTelemetry();

function FSTelemetry:update(dt)
	FSTelemetry.UpdateInterval.vehicleCurrent = FSTelemetry.UpdateInterval.vehicleCurrent + dt;
	if FSTelemetry.UpdateInterval.vehicleCurrent >= FSTelemetry.UpdateInterval.vehicle then
		FSTelemetry.UpdateInterval.vehicleCurrent = 0;

		FSTelemetry:RefreshPipe();
		if FSTelemetry.PipeControl.Pipe ~= nil then
			FSTelemetry.Telemetry.IsDrivingVehicle = FSTelemetry:IsDrivingVehicle();
			if FSTelemetry.Telemetry.IsDrivingVehicle then
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
	FSTelemetry.Telemetry.Money = 0.0;
	FSTelemetry.Telemetry.TemperatureMin = 0.0;
	FSTelemetry.Telemetry.TemperatureMax = 0.0;
	FSTelemetry.Telemetry.TempetatureTrend = 0;
	FSTelemetry.Telemetry.DayTimeMinutes = 0;
	FSTelemetry.Telemetry.WeatherCurrent = 0;
	FSTelemetry.Telemetry.WeatherNext = 0;
	FSTelemetry.Telemetry.Day = 0;
end

function FSTelemetry:ClearVehicleTelemetry()
	FSTelemetry.Telemetry.VehicleName = "";
	FSTelemetry.Telemetry.FuelMax = 0.0;
	FSTelemetry.Telemetry.Fuel = 0.0;
	FSTelemetry.Telemetry.RPMMin = 0;
	FSTelemetry.Telemetry.RPMMax = 0;
	FSTelemetry.Telemetry.RPM = 0;
	FSTelemetry.Telemetry.IsDrivingVehicle = false;
	FSTelemetry.Telemetry.IsAiActive = false;
	FSTelemetry.Telemetry.Wear = 0.0;
	FSTelemetry.Telemetry.OperationTimeMinutes = 0;
	FSTelemetry.Telemetry.Speed = 0;
	FSTelemetry.Telemetry.IsMotorStarted = false;
	FSTelemetry.Telemetry.Gear = 0;
	FSTelemetry.Telemetry.IsLightOn = false;
	FSTelemetry.Telemetry.IsLightHighOn = false;
	FSTelemetry.Telemetry.IsLightTurnRightEnabled = false;
	FSTelemetry.Telemetry.IsLightTurnRightOn = false;
	FSTelemetry.Telemetry.IsLightTurnLeftEnabled = false;
	FSTelemetry.Telemetry.IsLightTurnLeftOn = false;
	FSTelemetry.Telemetry.IsLightHazardOn = false;
	FSTelemetry.Telemetry.IsLightBeaconOn = false;
	FSTelemetry.Telemetry.IsWipersOn = false;
	FSTelemetry.Telemetry.IsCruiseControlOn = false;
	FSTelemetry.Telemetry.CruiseControlMaxSpeed = 0;
	FSTelemetry.Telemetry.CruiseControlSpeed = 0;
	FSTelemetry.Telemetry.IsHandBrakeOn = false;
	FSTelemetry.Telemetry.IsReverseDriving = false;
	FSTelemetry.Telemetry.IsMotorFanEnabled = false;
	FSTelemetry.Telemetry.MotorTemperature = 0.0;
	FSTelemetry.Telemetry.VehiclePrice = 0.0;
	FSTelemetry.Telemetry.VehicleSellPrice = 0.0;
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
	FSTelemetry:ProcessMotorStarted(specMotorized);
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
		FSTelemetry.Telemetry.IsMotorFanEnabled = motorized.motorFan.enabled;
	else
		FSTelemetry.Telemetry.IsMotorFanEnabled = false;
	end;
end

function FSTelemetry:ProcessMotorTemperature(motorized)
	if motorized ~= nil and motorized.motorTemperature ~= nil then
		FSTelemetry.Telemetry.MotorTemperature = motorized.motorTemperature.value;
	else
		FSTelemetry.Telemetry.MotorTemperature = 0;
	end;
end

function FSTelemetry:ProcessSpeed(vehicle, motorized)
	if motorized ~= nil and vehicle.getLastSpeed ~= nil then
		local lastSpeed = math.max(0, vehicle:getLastSpeed() * motorized.speedDisplayScale)
		FSTelemetry.Telemetry.Speed = math.floor(lastSpeed);
		if math.abs(lastSpeed - FSTelemetry.Telemetry.Speed) > 0.5 then
			FSTelemetry.Telemetry.Speed = FSTelemetry.Telemetry.Speed + 1;
		end
	else
		FSTelemetry.Telemetry.Speed = 0;
	end;
end

function FSTelemetry:ProcessRPM(motor)
	if motor ~= nil then
		if motor.getMinRpm ~= nil then
			FSTelemetry.Telemetry.RPMMin = math.ceil(motor:getMinRpm());
		else
			FSTelemetry.Telemetry.RPMMin = 0;
		end	

		if motor.getMaxRpm ~= nil then
			FSTelemetry.Telemetry.RPMMax = math.ceil(motor:getMaxRpm());
		else
			FSTelemetry.Telemetry.RPMMax = 0;
		end

		if motor.getLastRealMotorRpm ~= nil then
			FSTelemetry.Telemetry.RPM = math.ceil(motor:getLastRealMotorRpm());
		else
			FSTelemetry.Telemetry.RPM = 0;
		end
	end;
end

function FSTelemetry:ProcessPrice(vehicle)
	if vehicle ~= nil then
		if vehicle.getPrice ~= nil then
			FSTelemetry.Telemetry.VehiclePrice = vehicle:getPrice();
		else
			FSTelemetry.Telemetry.VehiclePrice = 0.0;
		end

		if vehicle.getSellPrice ~= nil then
			FSTelemetry.Telemetry.VehicleSellPrice = vehicle:getSellPrice();
		else
			FSTelemetry.Telemetry.VehicleSellPrice = 0.0;
		end
	end;
end

function FSTelemetry:ProcessGear(motor)
	if motor ~= nil then
		FSTelemetry.Telemetry.Gear = motor.gear;
	end;
end

function FSTelemetry:ProcessReverseDriving(vehicle, motorized)
	local reverserDirection = vehicle.getReverserDirection == nil and 1 or vehicle:getReverserDirection();
	FSTelemetry.Telemetry.IsReverseDriving = vehicle:getLastSpeed() > motorized.reverseDriveThreshold and vehicle.movingDirection ~= reverserDirection;
end

function FSTelemetry:ProcessMotorStarted(motorized)
	FSTelemetry.Telemetry.IsMotorStarted = motorized ~= nil and motorized.isMotorStarted;
end

function FSTelemetry:ProcessVehicleName(mission)
	FSTelemetry.Telemetry.Name = mission.currentVehicleName;
end

function FSTelemetry:ProcessAiActive(vehicle)
	FSTelemetry.Telemetry.IsAiActive = vehicle.getIsAIActive ~= nil and vehicle:getIsAIActive();
end

function FSTelemetry:ProcessWear(vehicle)
	if vehicle.getWearTotalAmount ~= nil and vehicle:getWearTotalAmount() ~= nil then
		FSTelemetry.Telemetry.Wear = vehicle:getWearTotalAmount();
	else
		FSTelemetry.Telemetry.Wear = 0;
	end;
end

function FSTelemetry:ProcessOperationTime(vehicle)
	if vehicle.operatingTime ~= nil then
		FSTelemetry.Telemetry.OperationTimeMinutes = vehicle.operatingTime / (1000 * 60);
	else
		FSTelemetry.Telemetry.OperationTimeMinutes = 0;
	end;
end

function FSTelemetry:ProcessFuelLevelAndCapacity(vehicle)
	--TODO: GET CURRENT FILL TYPE
	local fuelFillType = vehicle:getConsumerFillUnitIndex(FillType.DIESEL)
	if vehicle.getFillUnitCapacity ~= nil then
		FSTelemetry.Telemetry.FuelMax = vehicle:getFillUnitCapacity(fuelFillType);
	else
		FSTelemetry.Telemetry.FuelMax = 0;
	end;

	if vehicle.getFillUnitFillLevel ~= nil then
		FSTelemetry.Telemetry.Fuel = vehicle:getFillUnitFillLevel(fuelFillType);
	else
		FSTelemetry.Telemetry.Fuel = 0;
	end;
end

function FSTelemetry:ProcessCruiseControl(drivable)
	if drivable ~= nil then
		--Drivable.CRUISECONTROL_STATE_OFF
		--Drivable.CRUISECONTROL_STATE_ACTIVE
		--Drivable.CRUISECONTROL_STATE_FULL
		FSTelemetry.Telemetry.IsCruiseControlOn = drivable.cruiseControl.state ~= Drivable.CRUISECONTROL_STATE_OFF;
		FSTelemetry.Telemetry.CruiseControlSpeed = drivable.cruiseControl.speed;
		FSTelemetry.Telemetry.CruiseControlMaxSpeed = drivable.cruiseControl.maxSpeed;
	else
		FSTelemetry.Telemetry.IsCruiseControlOn = false;
		FSTelemetry.Telemetry.CruiseControlSpeed = 0;
		FSTelemetry.Telemetry.CruiseControlMaxSpeed = 0;
	end
end

--Aparently, it does'nt work
function FSTelemetry:ProcessHandBrake(drivable)
	if drivable ~= nil then
		FSTelemetry.Telemetry.IsHandBrakeOn = drivable.doHandbrake;
	else
		FSTelemetry.Telemetry.IsHandBrakeOn = false;
	end
end

function FSTelemetry:ProcessTurnLightsHazard(lights)
	if lights ~= nil and lights.turnLightState ~= nil then
		local state = lights.turnLightState;
		FSTelemetry.Telemetry.IsLightTurnRightEnabled = state == Lights.TURNLIGHT_RIGHT;
		FSTelemetry.Telemetry.IsLightTurnLeftEnabled = state == Lights.TURNLIGHT_LEFT;
		FSTelemetry.Telemetry.IsLightHazardOn = state == Lights.TURNLIGHT_HAZARD;

		local alpha = MathUtil.clamp((math.cos(7 * getShaderTimeSec()) + 0.2), 0, 1)
		FSTelemetry.Telemetry.IsLightTurnRightOn = (FSTelemetry.Telemetry.IsLightTurnRightEnabled or FSTelemetry.Telemetry.IsLightHazardOn) and alpha > 0.5;
		FSTelemetry.Telemetry.IsLightTurnLeftOn = (FSTelemetry.Telemetry.IsLightTurnLeftEnabled or FSTelemetry.Telemetry.IsLightHazardOn) and alpha > 0.5;
	else
		FSTelemetry.Telemetry.IsLightTurnRightEnabled = false;
		FSTelemetry.Telemetry.IsLightTurnRightOn = false;
		FSTelemetry.Telemetry.IsLightTurnLeftEnabled = false;
		FSTelemetry.Telemetry.IsLightTurnLeftOn = false;
		FSTelemetry.Telemetry.IsLightHazardOn = false;
	end;
end

function FSTelemetry:ProcessLightBeacon(lights)
	if lights ~= nil and lights.getBeaconLightsVisibility ~= nil then
		FSTelemetry.Telemetry.IsLightBeaconOn = lights.getBeaconLightsVisibility();
	else
		FSTelemetry.Telemetry.IsLightBeaconOn = false;
	end;
end

function FSTelemetry:ProcessLight(lights)
	if lights ~= nil and lights.lightsTypesMask ~= nil then
		--0 - LIGHT				
		--1 - TURN LIGHT
		--2 - FRONTAL LIGHT
		--3 - HIGH LIGHT

		FSTelemetry.Telemetry.IsLightOn = bitAND(specLights.lightsTypesMask, 2^0) ~= 0;
		FSTelemetry.Telemetry.IsLightHighOn = bitAND(specLights.lightsTypesMask, 2^3) ~= 0;
	else
		FSTelemetry.Telemetry.IsLightOn = false;
		FSTelemetry.Telemetry.IsLightHighOn = false;
	end;
end

function FSTelemetry:ProcessWiper(wipers, mission)
	FSTelemetry.Telemetry.IsWipersOn = false;
	if wipers ~= nil and wipers.hasWipers then
		local rainScale = (mission.environment ~= nil and mission.environment.weather ~= nil and mission.environment.weather.getRainFallScale ~= nil) and mission.environment.weather:getRainFallScale() or 0;
		if rainScale > 0 then
			for _, wiper in pairs(wipers.wipers) do
				for stateIndex,state in ipairs(wiper.states) do
					if rainScale <= state.maxRainValue then
						FSTelemetry.Telemetry.IsWipersOn = true;
						break
					end
				end
				if FSTelemetry.Telemetry.IsWipersOn then
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
			FSTelemetry.Telemetry.Money = farm.money;
			--g_currentMission.mission.missionInfo.money
		end
    end

	if g_currentMission.environment ~= nil then
		local environment = g_currentMission.environment;
		if environment.weather ~= nil then
			local minTemp, maxTemp = environment.weather:getCurrentMinMaxTemperatures();
			FSTelemetry.Telemetry.TemperatureMin = minTemp;
			FSTelemetry.Telemetry.TemperatureMax = maxTemp;
			FSTelemetry.Telemetry.TempetatureTrend = environment.weather:getCurrentTemperatureTrend();
		end

		FSTelemetry.Telemetry.DayTimeMinutes = environment.dayTime / (1000 * 60);

		local sixHours = 6 * 60 * 60 * 1000;
		local dayPlus6h, timePlus6h = environment:getDayAndDayTime(environment.dayTime + sixHours, environment.currentDay);
		FSTelemetry.Telemetry.WeatherCurrent = environment.weather:getWeatherTypeAtTime(environment.currentDay, environment.dayTime);
		FSTelemetry.Telemetry.WeatherNext = environment.weather:getWeatherTypeAtTime(dayPlus6h, timePlus6h);

		FSTelemetry.Telemetry.Day = environment.currentDay;
	end
end

function  FSTelemetry:BuildHeaderText()
	local text = FSTelemetry:AddText("HEADER", "");
	for k, v in pairs(FSTelemetry.Telemetry) do
		text = FSTelemetry:AddText(k, text);
	end
	return text;
end 

function FSTelemetry:BuildBodyText()
	local text = FSTelemetry:AddText("BODY", "");
	for key, value in pairs(FSTelemetry.Telemetry) do
		local type = type(value);
		if type == "boolean" then
			text = FSTelemetry:AddTextBoolean(value, text);
		elseif type == "string" then
			text = FSTelemetry:AddText(value, text);
		elseif type =="number" then
			if math.type(value) == "integer" then
				text = FSTelemetry:AddTextNumber(value, text);
			else
				text = FSTelemetry:AddTextDecimal(value, text);
			end
		end
	end
	return text;
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
	return text .. value .. "§";
end

function FSTelemetry:WriteTelemetry()
	if FSTelemetry.PipeControl.RefreshCurrent == 0 then
		FSTelemetry.PipeControl.Pipe:write(FSTelemetry:BuildHeaderText());
		FSTelemetry.PipeControl.Pipe:flush();
	end

	FSTelemetry.PipeControl.Pipe:write(FSTelemetry:BuildBodyText());
	FSTelemetry.PipeControl.Pipe:flush();
end

function FSTelemetry:RefreshPipe()
	if FSTelemetry.PipeControl.RefreshCurrent == 0 then
		if FSTelemetry.PipeControl.Pipe ~= nil then
			FSTelemetry.PipeControl.Pipe:flush();
			FSTelemetry.PipeControl.Pipe:close();
		end

		FSTelemetry.PipeControl.Pipe = io.open(FSTelemetry.PipeName, "w");
	end

	FSTelemetry.PipeControl.RefreshCurrent = FSTelemetry.PipeControl.RefreshCurrent + 1;
	if FSTelemetry.PipeControl.RefreshCurrent >= FSTelemetry.PipeControl.RefreshRate then
		FSTelemetry.PipeControl.RefreshCurrent = 0;
	end
end

addModEventListener(FSTelemetry);