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
		DisableActiveExtras(vehicle)

		if PrimarySirenActivated then
			TriggerServerEvent('ALS:StopPrimarySirenServer', GetVehicleNetId(vehicle))
			PrimarySirenActivated = false
		end
		if SecondarySirenActivated then
			TriggerServerEvent('ALS:StopSecondarySirenServer', GetVehicleNetId(vehicle))
			SecondarySirenActivated = false
		end
	else
		for model, vehicleConfig in pairs(Config.Vehicles) do
			if GetEntityModel(vehicle) == GetHashKey(model) then
				PrimaryLightsActivated = true
				Citizen.CreateThread(function()
					EnablePrimaryStage(vehicle, vehicleConfig)
				end)
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
		DisableActiveExtras(vehicle)
	else
		for model, vehicleConfig in pairs(Config.Vehicles) do
			if GetEntityModel(vehicle) == GetHashKey(model) then
				SecondaryLightsActivated = true
				Citizen.CreateThread(function()
					EnableSecondaryStage(vehicle, vehicleConfig)
				end)
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
		DisableActiveExtras(vehicle)
	else
		for model, vehicleConfig in pairs(Config.Vehicles) do
			if GetEntityModel(vehicle) == GetHashKey(model) then
				WarningLightsActivated = true
				Citizen.CreateThread(function()
					EnableWarningStage(vehicle, vehicleConfig)
				end)
				break
			end
		end
	end
end)

RegisterCommand('AG-ALS-FiveM-PrimarySiren', function()
	local ped = PlayerPedId()
	local vehicle = GetVehiclePedIsUsing(ped)
	if ALSLocked or SecondarySirenActivated or not PrimaryLightsActivated then return end

	if PrimarySirenActivated then
		TriggerServerEvent('ALS:StopPrimarySirenServer', GetVehicleNetId(vehicle))
		PrimarySirenActivated = false
	else
		TriggerServerEvent('ALS:PlayPrimarySirenServer', GetVehicleNetId(vehicle))
		PrimarySirenActivated = true
	end
end)

RegisterCommand('AG-ALS-FiveM-SecondarySiren', function()
	local ped = PlayerPedId()
	local vehicle = GetVehiclePedIsUsing(ped)
	if ALSLocked or PrimarySirenActivated or not PrimaryLightsActivated then return end

	if SecondarySirenActivated then
		TriggerServerEvent('ALS:StopSecondarySirenServer', GetVehicleNetId(vehicle))
		SecondarySirenActivated = false
	else
		TriggerServerEvent('ALS:PlaySecondarySirenServer', GetVehicleNetId(vehicle))
		SecondarySirenActivated = true
	end
end)

RegisterCommand('ALSPanel', function()
	ModuleOpen = not ModuleOpen
end)
