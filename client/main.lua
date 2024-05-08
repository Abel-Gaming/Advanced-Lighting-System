print('Loaded ELS by Abel Gaming')
RegisterKeyMapping('AG-ELS-FiveM-Primary', 'Toggle primary lights', 'KEYBOARD', 'Q')
RegisterKeyMapping('AG-ELS-FiveM-Lock', 'Lock ELS', 'KEYBOARD', 'F24')
local LightsActivated = false
local ELSLocked = false

RegisterCommand('AG-ELS-FiveM-Lock', function()
	ELSLocked = not ELSLocked
end)

RegisterCommand('AG-ELS-FiveM-Primary', function()
	if not ELSLocked then
		local ped = PlayerPedId()
		if LightsActivated then
			local vehicle = GetVehiclePedIsIn(ped)
			SetVehicleSiren(vehicle, false)
			DisableLights(vehicle)
			LightsActivated = false
		else
			local vehicle = GetVehiclePedIsUsing(ped)
			for k,v in pairs(Config.Vehicles) do
				if GetEntityModel(vehicle) == GetHashKey(k) then
					local vehicleConfig = Config.Vehicles[k]
					Citizen.CreateThread(function()
						EnablePrimaryStage(vehicleConfig)
					end)
					break
				end
			end
			LightsActivated = true
		end
	end
end)

function EnablePrimaryStage(vehicleConfig)
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsUsing(ped)
    while LightsActivated do
        Citizen.Wait(1)
        if IsPedInAnyVehicle(ped) then
            SetVehicleAutoRepairDisabled(vehicle, true)
            SetVehicleSiren(vehicle, true)
            SetVehicleHasMutedSirens(vehicle, true)

            local pattern = Config.Patterns[vehicleConfig.Pattern]
            if pattern then
                for _, stage in ipairs(pattern.Stages) do
                    for _, extraIndex in ipairs(stage.Extras) do
                        SetVehicleExtra(vehicle, extraIndex, 0)
                    end
                    Citizen.Wait(pattern.FlashDelay)
                    for _, extraIndex in ipairs(stage.Extras) do
                        SetVehicleExtra(vehicle, extraIndex, 1)
                    end
                end
            end
        end
    end
end

function DisableLights(vehicle)
	if not LightsActivated then
		local ped = PlayerPedId()
		local vehicle = GetVehiclePedIsUsing(ped)
		if vehicle ~= 0 then
			SetVehicleExtra(vehicle, 1, 1)
			SetVehicleExtra(vehicle, 2, 1)
			SetVehicleExtra(vehicle, 3, 1)
			SetVehicleExtra(vehicle, 4, 1)
			SetVehicleExtra(vehicle, 5, 1)
			SetVehicleExtra(vehicle, 6, 1)
			SetVehicleExtra(vehicle, 7, 1)
			SetVehicleExtra(vehicle, 8, 1)
			SetVehicleExtra(vehicle, 9, 1)
			SetVehicleExtra(vehicle, 10, 1)
		end
	end
end

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)	
		if ELSLocked then
			-- Draw text
			SetTextFont(0)
            SetTextProportional(1)
            SetTextScale(0.0, 0.3)
            SetTextDropshadow(0, 0, 0, 0, 255)
            SetTextEdge(1, 0, 0, 0, 255)
            SetTextDropShadow()
            SetTextOutline()
            SetTextEntry("STRING")
            AddTextComponentString("~r~ELS Locked")
            DrawText(0.005, 0.5)
		end
	end
end)