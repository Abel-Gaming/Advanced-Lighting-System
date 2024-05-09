RegisterCommand('AG-ALS-FiveM-Lock', function()
	ALSLocked = not ALSLocked
end)

RegisterCommand('AG-ALS-FiveM-Primary', function()
	if not ALSLocked then
		local ped = PlayerPedId()
		if PrimaryLightsActivated then
			local vehicle = GetVehiclePedIsIn(ped)
			SetVehicleSiren(vehicle, false)
			--DisableLights(vehicle)
			DisableActiveExtras()
			PrimaryLightsActivated = false
		else
			local vehicle = GetVehiclePedIsUsing(ped)
			for k,v in pairs(Config.Vehicles) do
				if GetEntityModel(vehicle) == GetHashKey(k) then
					local vehicleConfig = Config.Vehicles[k]
					TriggerServerEvent('ALS:TogglePrimaryLights', vehicle, vehicleConfig)
					break
				end
			end
			PrimaryLightsActivated = true
		end
	end
end)

RegisterCommand('AG-ALS-FiveM-Secondary', function()
	if not ALSLocked then
		local ped = PlayerPedId()
		if SecondaryLightsActivated then
			local vehicle = GetVehiclePedIsIn(ped)
			--DisableLights(vehicle)
			DisableActiveExtras()
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
end)

RegisterCommand('AG-ALS-FiveM-Warning', function()
	if not ALSLocked then
		local ped = PlayerPedId()
		if WarningLightsActivated then
			local vehicle = GetVehiclePedIsIn(ped)
			--DisableLights(vehicle)
			DisableActiveExtras()
			WarningLightsActivated = false
		else
			local vehicle = GetVehiclePedIsUsing(ped)
			for k,v in pairs(Config.Vehicles) do
				if GetEntityModel(vehicle) == GetHashKey(k) then
					local vehicleConfig = Config.Vehicles[k]
					--Citizen.CreateThread(function()
						--EnableWarningStage(vehicleConfig)
					--end)
					TriggerServerEvent('ALS:ToggleWarningLights', vehicle, vehicleConfig)
					break
				end
			end
			WarningLightsActivated = true
		end
	end
end)

function ArePrimaryLightsActivated()
	return PrimaryLightsActivated
end

function AreSecondaryLightsActivated()
	return SecondaryLightsActivated
end

function AreWarningLightsActivated()
	return WarningLightsActivated
end

function IsControlModuleOpen()
	return ModuleOpen
end

function IsPrimarySirenActive()
	return PrimarySirenActivated
end

----- Draw Text if ALS is Locked -----
Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)	
		if ALSLocked then
			-- Draw text
			SetTextFont(0)
            SetTextProportional(1)
            SetTextScale(0.0, 0.3)
            SetTextDropshadow(0, 0, 0, 0, 255)
            SetTextEdge(1, 0, 0, 0, 255)
            SetTextDropShadow()
            SetTextOutline()
            SetTextEntry("STRING")
            AddTextComponentString("~r~ALS Locked")
            DrawText(0.005, 0.5)
		end
	end
end)

----- Listen For Siren Presses -----
Citizen.CreateThread(function()
	while true do
		Citizen.Wait(1)

		-- GET THE PLAYER VEHICLE --
		local ped = PlayerPedId()
		local vehicle = GetVehiclePedIsUsing(ped)

		----- PRIMARY SIREN -----
		if IsControlJustPressed(0, 19) and PrimaryLightsActivated and not ALSLocked and not SecondarySirenActivated then
			if PrimarySirenActivated then
				TriggerServerEvent('ALS:StopPrimarySirenServer', vehicle)
				PrimarySirenActivated = false
			else
				TriggerServerEvent('ALS:PlayPrimarySirenServer', vehicle)
				PrimarySirenActivated = true
			end
		end

		----- SECONDARY SIREN -----
		if IsControlJustPressed(0, 172) and PrimaryLightsActivated and not ALSLocked and not PrimarySirenActivated then
			if SecondarySirenActivated then
				TriggerServerEvent('ALS:StopSecondarySirenServer', vehicle)
				SecondarySirenActivated = false
			else
				TriggerServerEvent('ALS:PlaySecondarySirenServer', vehicle)
				SecondarySirenActivated = true
			end
		end
	end
end)