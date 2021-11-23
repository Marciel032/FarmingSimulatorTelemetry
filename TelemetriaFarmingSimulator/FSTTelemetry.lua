FSTelemetry = {};

local refreshInterval = 300;
local currentRefreshInterval = 0;
local drivingVehicleLastState = false;
local nameLastState = "";

local tempDirectory = os.getenv('TEMP');
local dynamicFilePath = tempDirectory .. "\\dynamicTelemetry.sim";
local staticFilePath = tempDirectory .. "\\staticTelemetry.sim";

local dynamicTelemetry = {}
local staticTelemetry = {}

local clearTelemetry = function()
	staticTelemetry.Name = "";
	staticTelemetry.FuelMax = 0.0;
	staticTelemetry.RPMMax = 0;

	dynamicTelemetry.Wear = 0.0;
	dynamicTelemetry.OperationTime = 0;
	dynamicTelemetry.Speed = 0;	
	dynamicTelemetry.Fuel = 0.0;	
	dynamicTelemetry.RPM = 0;
	dynamicTelemetry.IsMotorStarted = false;
	dynamicTelemetry.Gear = 0;
	dynamicTelemetry.IsLightOn = false;
	dynamicTelemetry.IsLightHighOn = false;
	dynamicTelemetry.IsLightTurnRightOn = false;
	dynamicTelemetry.IsLightTurnLeftOn = false;
	dynamicTelemetry.IsLightHazardOn = false;	
	dynamicTelemetry.IsWipersOn = false;
end

local addText = function(text, value)
	return text .. value .. ";";
end

local formatDecimal = function(value)
	return string.format("%.2f", value)
end

local formatNumber = function(value)
	return string.format("%d", value)
end

local buildDynamicText = function()
	local text = addText("", formatDecimal(dynamicTelemetry.Wear))
	text = addText(text, formatNumber(dynamicTelemetry.OperationTime));
	text = addText(text, formatNumber(dynamicTelemetry.Speed));
	text = addText(text, formatDecimal(dynamicTelemetry.Fuel));
	text = addText(text, formatNumber(dynamicTelemetry.RPM));
	text = addText(text, tostring(dynamicTelemetry.isMotorStarted));
	text = addText(text, formatNumber(dynamicTelemetry.Gear));
	text = addText(text, tostring(dynamicTelemetry.IsLightOn));
	text = addText(text, tostring(dynamicTelemetry.IsLightHighOn));
	text = addText(text, tostring(dynamicTelemetry.IsLightTurnRightOn));
	text = addText(text, tostring(dynamicTelemetry.IsLightTurnLeftOn));
	text = addText(text, tostring(dynamicTelemetry.IsLightHazardOn));
	text = addText(text, tostring(dynamicTelemetry.IsWipersOn));
	return text;
end 

local buildStaticText = function()
	local text = addText("", staticTelemetry.Name)
	text = addText(text, formatDecimal(staticTelemetry.FuelMax));
	text = addText(text, formatNumber(staticTelemetry.RPMMax));
	return text;
end 

local writeFile = function(name, content){
	local file = io.open(name, "w");
	if file ~= nil then
		file:write(content);
		file:close();
	end;
}

local writeDynamicFile = function()
	writeFile(dynamicFilePath, buildDynamicText());
end

local writeStaticFile = function()
	writeFile(staticFilePath, buildStaticText());
end

function FSTelemetry:update(dt)	
	currentRefreshInterval = currentRefreshInterval + dt;
	if currentRefreshInterval >= refreshInterval then
		currentRefreshInterval = 0;		

		local vehicle = g_currentMission.controlledVehicle;
		local hasVehicle = vehicle ~= nil;
		local isMotorized = vehicle.spec_motorized ~= nil;
		--TODO - Check vehicle is driving by IA
		local drivingVehicle = hasVehicle and isMotorized;

		if drivingVehicle then
			local specMotorized = vehicle.spec_motorized;
			if specMotorized ~= nil then
				dynamicTelemetry.IsMotorStarted = specMotorized.isMotorStarted;
			end;

			dynamicTelemetry.Name = vehicle:getName();
			if vehicle.getWearTotalAmount ~= nil and vehicle:getWearTotalAmount() ~= nil then
				dynamicTelemetry.Wear = vehicle:getWearTotalAmount();
			end;

			if vehicle.operatingTime ~= nil then
				dynamicTelemetry.OperationTime = vehicle.operatingTime;
			end;

			local lastSpeed = math.max(0, vehicle:getLastSpeed() * vehicle.spec_motorized.speedDisplayScale)
			dynamicTelemetry.Speed = math.floor(lastSpeed);
			if math.abs(lastSpeed-dynamicTelemetry.Speed) > 0.5 then
				dynamicTelemetry.Speed = dynamicTelemetry.Speed + 1
			end

			--TODO: GET CURRENT FILL TYPE
			local fuelFillType = vehicle:getConsumerFillUnitIndex(FillType.DIESEL)
			if vehicle.getFillUnitCapacity ~= nil then
				dynamicTelemetry.FuelMax = vehicle:getFillUnitCapacity(fuelFillType);
			end;

			if vehicle.getFillUnitFillLevel ~= nil then
				dynamicTelemetry.Fuel = vehicle:getFillUnitFillLevel(fuelFillType);
			end;						

			local motor = vehicle:getMotor();
			if motor ~= nil then	
				if motor.getMaxRpm ~= nil then
					dynamicTelemetry.RPMMax = math.ceil(motor:getMaxRpm());
				end	
				if motor.getLastRealMotorRpm ~= nil and dynamicTelemetry.IsMotorStarted then
					dynamicTelemetry.RPM = math.ceil(motor:getLastRealMotorRpm());
				end		
				dynamicTelemetry.Gear = motor.gear;					
			end;

			local specLights = vehicle.spec_lights;
			if specLights ~= nil then
				if specLights.turnLightState ~= nil then
					local state = specLights.turnLightState;
					dynamicTelemetry.IsLightTurnRightOn = state	== Lights.TURNLIGHT_RIGHT;
					dynamicTelemetry.IsLightTurnLeftOn = state == Lights.TURNLIGHT_LEFT;
					dynamicTelemetry.IsLightHazardOn = state == Lights.TURNLIGHT_HAZARD;

					--TODO: CALCULATE TURN LIGHT BLINK
					--local alpha = MathUtil.clamp((math.cos(7*getShaderTimeSec()) + 0.2), 0, 1)
				end;


				--0 - LIGHT				
				--1 - TURN LIGHT
				--2 - FRONTAL LIGHT
				--3 - HIGH LIGHT
				if specLights.lightsTypesMask ~= nil then
					dynamicTelemetry.IsLightOn = bitAND(specLights.lightsTypesMask, 2^0) ~= 0;
					dynamicTelemetry.IsLightHighOn = bitAND(specLights.lightsTypesMask, 2^3) ~= 0;
				end;
			end;			

			local specWipers = vehicle.spec_wipers;
			if specWipers ~= nil and specWipers.hasWipers and dynamicTelemetry.isMotorStarted then
				local rainScale = g_currentMission.environment.weather:getRainFallScale();
				if rainScale > 0 then
					for _, wiper in pairs(specWipers.wipers) do
						for stateIndex,state in ipairs(wiper.states) do
							if rainScale <= state.maxRainValue then
								dynamicTelemetry.IsWipersOn = true;
								break
							end
						end
						if dynamicTelemetry.IsWipersOn then
							break;
						end
					end
				end
			end;			
			writeDynamicFile();
			--Just write static file when player change the vehicle
			if nameLastState ~= staticTelemetry.Name then
				writeStaticFile();
			end			
		else
			-- Just write file a sigle time when player get out vehicle
			if drivingVehicleLastState then			
				clearTelemetry();
				writeDynamicFile();
				writeStaticFile();
			end
		end;
				
		nameLastState = staticTelemetry.Name;
		drivingVehicleLastState = drivingVehicle;
		--print(DebugUtil.printTableRecursively(g_currentMission.controlledVehicle,".",0,5));
	end;	
end

addModEventListener(FSTelemetry);