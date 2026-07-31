local function isInEmergencyVehicle(veh)
    return veh ~= 0 and GetVehicleClass(veh) == 18
end

RegisterCommand('AG-ALS-FiveM-Lock', function()
	ALSLocked = not ALSLocked
end)

RegisterCommand('AG-ALS-FiveM-Primary', function()
	local ped = PlayerPedId()
	local vehicle = GetVehiclePedIsUsing(ped)
	if ALSLocked or not isInEmergencyVehicle(vehicle) then return end

	if PrimaryLightsActivated then
		PrimaryLightsActivated = false
		Entity(vehicle).state:set('elsPrimary', nil, true)
		DisableActiveExtras(vehicle)

		if ActiveSirenTone then
			ClearVehicleSirenState(vehicle)
			ActiveSirenTone = nil
		end
	else
		for model, vehicleConfig in pairs(Config.Vehicles) do
			if GetEntityModel(vehicle) == GetHashKey(model) then
				PrimaryLightsActivated = true
				Entity(vehicle).state:set('elsPrimary', { patternId = vehicleConfig.Pattern }, true)
				break
			end
		end
	end
end)

RegisterCommand('AG-ALS-FiveM-Secondary', function()
	local ped = PlayerPedId()
	local vehicle = GetVehiclePedIsUsing(ped)
	if ALSLocked or not isInEmergencyVehicle(vehicle) then return end

	if SecondaryLightsActivated then
		SecondaryLightsActivated = false
		Entity(vehicle).state:set('elsSecondary', nil, true)
		DisableActiveExtras(vehicle)
	else
		for model, vehicleConfig in pairs(Config.Vehicles) do
			if GetEntityModel(vehicle) == GetHashKey(model) then
				SecondaryLightsActivated = true
				Entity(vehicle).state:set('elsSecondary', { patternId = vehicleConfig.Pattern }, true)
				break
			end
		end
	end
end)

RegisterCommand('AG-ALS-FiveM-Warning', function()
	local ped = PlayerPedId()
	local vehicle = GetVehiclePedIsUsing(ped)
	if ALSLocked or not isInEmergencyVehicle(vehicle) then return end

	if WarningLightsActivated then
		WarningLightsActivated = false
		Entity(vehicle).state:set('elsWarning', nil, true)
		DisableActiveExtras(vehicle)
	else
		for model, vehicleConfig in pairs(Config.Vehicles) do
			if GetEntityModel(vehicle) == GetHashKey(model) then
				WarningLightsActivated = true
				Entity(vehicle).state:set('elsWarning', { patternId = vehicleConfig.Pattern }, true)
				break
			end
		end
	end
end)

local function toggleSirenTone(tone)
	local ped = PlayerPedId()
	local vehicle = GetVehiclePedIsUsing(ped)
	if ALSLocked or (not Config.SirenAlwaysAllowed and not PrimaryLightsActivated) then return end

	if ActiveSirenTone == tone then
		ClearVehicleSirenState(vehicle)
		ActiveSirenTone = nil
	else
		SetVehicleSirenState(vehicle, tone)
		ActiveSirenTone = tone
	end
end

RegisterCommand('AG-ALS-FiveM-Siren1', function() toggleSirenTone(1) end)
RegisterCommand('AG-ALS-FiveM-Siren2', function() toggleSirenTone(2) end)
RegisterCommand('AG-ALS-FiveM-Siren3', function() toggleSirenTone(3) end)
RegisterCommand('AG-ALS-FiveM-Siren4', function() toggleSirenTone(4) end)

RegisterCommand('ALSPanel', function()
	ModuleOpen = not ModuleOpen
end)