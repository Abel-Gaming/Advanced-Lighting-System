RegisterCommand('AG-ALS-FiveM-Lock', function()
	ALSLocked = not ALSLocked
end)

RegisterCommand('AG-ALS-FiveM-Primary-Old', function()
	local ped = PlayerPedId()
	local veh = GetVehiclePedIsUsing(ped)
	if GetVehicleClass(veh) == 18 then
		if not ALSLocked then
			local ped = PlayerPedId()
			if PrimaryLightsActivated then
				local vehicle = GetVehiclePedIsUsing(ped)
				DisableActiveExtras(vehicle)
				if PrimarySirenActivated then
					TriggerServerEvent('ALS:StopPrimarySirenServer', vehicle)
					PrimarySirenActivated = false
				end
				if SecondarySirenActivated then
					TriggerServerEvent('ALS:StopSecondarySirenServer', vehicle)
					SecondarySirenActivated = false
				end
				PrimaryLightsActivated = false
			else
				local vehicle = GetVehiclePedIsUsing(ped)
				for k,v in pairs(Config.Vehicles) do
					if GetEntityModel(vehicle) == GetHashKey(k) then
						local vehicleConfig = Config.Vehicles[k]
						Citizen.CreateThread(function()
							EnablePrimaryStage(vehicle, vehicleConfig)
						end)
						break
					end
				end
				PrimaryLightsActivated = true
			end
		end
	end
end)

RegisterCommand('AG-ALS-FiveM-Primary', function()
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsUsing(ped)

    -- Make sure that the vehicle exists in the activeVehicles Table
    local vehicleFound = false
    for _, data in ipairs(activeVehicles) do
        if data.entity == vehicle then
            vehicleFound = true
            break
        end
    end

    if not vehicleFound then
        local myServerId = GetPlayerServerId(PlayerId())
        local vehicleData = {
            entity = vehicle,
            owner = myServerId,
            PrimaryLights = false,
            SecondaryLights = false,
            WarningLights = false,
            PrimarySiren = false,
            SecondrySiren = false,
        }
        table.insert(activeVehicles, vehicleData)
        SetVehicleAutoRepairDisabled(vehicle, true)
    else
    end

    if GetVehicleClass(vehicle) == 18 then
        for _, data in ipairs(activeVehicles) do
            if data.entity == vehicle then
                if data.PrimaryLights then
                    data.PrimaryLights = false
                else
                    data.PrimaryLights = true
                    for k,v in pairs(Config.Vehicles) do
                        if GetEntityModel(data.entity) == GetHashKey(k) then
                            local vehicleConfig = Config.Vehicles[k]
                            Citizen.CreateThread(function()
                                TogglePrimaryStage(data.entity, vehicleConfig, data)
                            end)
                        end
                    end
                end
            end
        end
    end
end)

RegisterCommand('AG-ALS-FiveM-Secondary', function()
	local ped = PlayerPedId()
	local veh = GetVehiclePedIsUsing(ped)
	if GetVehicleClass(veh) == 18 then
		if not ALSLocked then
			local ped = PlayerPedId()
			if SecondaryLightsActivated then
				local vehicle = GetVehiclePedIsUsing(ped)
				TriggerServerEvent('ALS:DisableLights', vehicle)
				SecondaryLightsActivated = false
			else
				local vehicle = GetVehiclePedIsUsing(ped)
				for k,v in pairs(Config.Vehicles) do
					if GetEntityModel(vehicle) == GetHashKey(k) then
						local vehicleConfig = Config.Vehicles[k]
						TriggerServerEvent('ALS:ToggleSecondaryLights', vehicle, vehicleConfig)
						break
					end
				end
				SecondaryLightsActivated = true
			end
		end
	end
end)

RegisterCommand('AG-ALS-FiveM-Warning', function()
	local ped = PlayerPedId()
	local veh = GetVehiclePedIsUsing(ped)
	if GetVehicleClass(veh) == 18 then
		if not ALSLocked then
			local ped = PlayerPedId()
			if WarningLightsActivated then
				local vehicle = GetVehiclePedIsUsing(ped)
				local vehicle = GetVehiclePedIsUsing(ped)
				TriggerServerEvent('ALS:DisableLights', vehicle)
				WarningLightsActivated = false
			else
				local vehicle = GetVehiclePedIsUsing(ped)
				for k,v in pairs(Config.Vehicles) do
					if GetEntityModel(vehicle) == GetHashKey(k) then
						local vehicleConfig = Config.Vehicles[k]
						TriggerServerEvent('ALS:ToggleWarningLights', vehicle, vehicleConfig)
						break
					end
				end
				WarningLightsActivated = true
			end
		end
	end
end)

RegisterCommand('AG-ALS-FiveM-PrimarySiren', function()
	local ped = PlayerPedId()
	local vehicle = GetVehiclePedIsUsing(ped)
	if PrimaryLightsActivated and not ALSLocked and not SecondarySirenActivated then
		if PrimarySirenActivated then
			TriggerServerEvent('ALS:StopPrimarySirenServer', vehicle)
			PrimarySirenActivated = false
		else
			TriggerServerEvent('ALS:PlayPrimarySirenServer', vehicle)
			PrimarySirenActivated = true
		end
	end
end)

RegisterCommand('AG-ALS-FiveM-SecondarySiren', function()
	local ped = PlayerPedId()
	local vehicle = GetVehiclePedIsUsing(ped)
	if PrimaryLightsActivated and not ALSLocked and not PrimarySirenActivated then
		if SecondarySirenActivated then
			TriggerServerEvent('ALS:StopSecondarySirenServer', vehicle)
			SecondarySirenActivated = false
		else
			TriggerServerEvent('ALS:PlaySecondarySirenServer', vehicle)
			SecondarySirenActivated = true
		end
	end
end)

RegisterCommand('ALSPanel', function()
	ModuleOpen = not ModuleOpen
end)