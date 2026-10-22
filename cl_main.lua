-- The vehicle the player last controlled ALS on (used by AutoOff)
LastALSVehicle = nil

local stageBagKeys = {
	Primary = 'elsPrimary',
	Secondary = 'elsSecondary',
	Warning = 'elsWarning',
}

local function getMyEmergencyVehicle()
	local vehicle = GetVehiclePedIsUsing(PlayerPedId())
	if vehicle == 0 or GetVehicleClass(vehicle) ~= 18 then return nil end
	return vehicle
end

RegisterCommand('AG-ALS-FiveM-Lock', function()
	ALSLocked = not ALSLocked
end)

local function toggleStage(stageName)
	if ALSLocked then return end
	local vehicle = getMyEmergencyVehicle()
	if not vehicle then return end

	local key = stageBagKeys[stageName]
	local state = Entity(vehicle).state
	LastALSVehicle = vehicle

	if state[key] then
		state:set(key, nil, true)
		-- Turning primary off also kills the siren (same as before)
		if stageName == 'Primary' and state.elsSiren then
			ClearVehicleSirenState(vehicle)
		end
	else
		local cfg = GetVehicleConfig(vehicle)
		if not cfg then return end
		state:set(key, { patternId = cfg.Pattern }, true)
	end
end

RegisterCommand('AG-ALS-FiveM-Primary', function() toggleStage('Primary') end)
RegisterCommand('AG-ALS-FiveM-Secondary', function() toggleStage('Secondary') end)
RegisterCommand('AG-ALS-FiveM-Warning', function() toggleStage('Warning') end)

local function toggleSirenTone(tone)
	if ALSLocked then return end
	local vehicle = getMyEmergencyVehicle()
	if not vehicle then return end

	local state = Entity(vehicle).state
	if not Config.SirenAlwaysAllowed and not state.elsPrimary then return end
	LastALSVehicle = vehicle

	local current = state.elsSiren
	if current and current.active and current.tone == tone then
		ClearVehicleSirenState(vehicle)
	else
		SetVehicleSirenState(vehicle, tone)
	end
end

RegisterCommand('AG-ALS-FiveM-Siren1', function() toggleSirenTone(1) end)
RegisterCommand('AG-ALS-FiveM-Siren2', function() toggleSirenTone(2) end)
RegisterCommand('AG-ALS-FiveM-Siren3', function() toggleSirenTone(3) end)
RegisterCommand('AG-ALS-FiveM-Siren4', function() toggleSirenTone(4) end)

RegisterCommand('ALSPanel', function()
	ModuleOpen = not ModuleOpen
end)
