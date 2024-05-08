print('Loaded ELS by Abel Gaming')

local LightsActivated = false

RegisterCommand('AG-ELS-FiveM-Primary', function()
	if LightsActivated then
		local vehicle = GetVehiclePedIsIn(PlayerPedId())
		SetVehicleSiren(vehicle, false)
		LightsActivated = false
	else
		local ped = PlayerPedId()
		local vehicle = GetVehiclePedIsUsing(ped)
		local modelName = GetDisplayNameFromVehicleModel(GetEntityModel(vehicle))
		local vehicleConfig = Config.Vehicles[modelName]
		print('Model Name: ' .. modelName)
		print('Player Vehicle: ' .. vehicle)
		LightsActivated = true
		EnablePrimaryStage(vehicleConfig)
	end
end)

RegisterKeyMapping('AG-ELS-FiveM-Primary', 'Toggle primary lights', 'KEYBOARD', 'Q')

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1)
        if LightsActivatedOld then
            if IsPedInAnyVehicle(GetPlayerPed(-1)) then
                local ped = PlayerPedId()
                local vehicle = GetVehiclePedIsUsing(ped)

                -- Disable vehicle from repairing with extras
                SetVehicleAutoRepairDisabled(vehicle, true)

				-- Enable siren but mute it
				SetVehicleSiren(vehicle, true)
				SetVehicleHasMutedSirens(vehicle, true)

                -- Enable Extras for First Flash
                SetVehicleExtra(vehicle, 1, 0)
                SetVehicleExtra(vehicle, 3, 0)
                SetVehicleExtra(vehicle, 7, 0)

                -- Flash Delay
                Citizen.Wait(250) -- Adjust the delay as needed

                -- Disable Extras for stage 1
                SetVehicleExtra(vehicle, 1, 1)
                SetVehicleExtra(vehicle, 3, 1)
                SetVehicleExtra(vehicle, 7, 1)

                -- Enable Extras for Second Flash
                SetVehicleExtra(vehicle, 2, 0)
                SetVehicleExtra(vehicle, 4, 0)
                SetVehicleExtra(vehicle, 9, 0)

                -- Flash Delay
                Citizen.Wait(250) -- Adjust the delay as needed

                -- Disable Extras for stage 2
                SetVehicleExtra(vehicle, 2, 1)
                SetVehicleExtra(vehicle, 4, 1)
                SetVehicleExtra(vehicle, 9, 1)
            end
		else
			local ped = PlayerPedId()
            local vehicle = GetVehiclePedIsUsing(ped)
			SetVehicleExtra(vehicle, 1, 1)
            SetVehicleExtra(vehicle, 3, 1)
            SetVehicleExtra(vehicle, 7, 1)
			SetVehicleExtra(vehicle, 2, 1)
            SetVehicleExtra(vehicle, 4, 1)
            SetVehicleExtra(vehicle, 9, 1)
        end
    end
end)

Citizen.CreateThread(function()
    print("Script started execution") -- Add a print statement at the beginning of the script
    while true do
        Citizen.Wait(1)
        if LightsActivatedTest then
            print("Lights are activated") -- Add a print statement when lights are activated
            if IsPedInAnyVehicle(GetPlayerPed(-1)) then
                print("Player is in a vehicle") -- Add a print statement when player is in a vehicle
                local ped = PlayerPedId()
                local vehicle = GetVehiclePedIsUsing(ped)
                print("Vehicle model: " .. GetDisplayNameFromVehicleModel(GetEntityModel(vehicle))) -- Print the vehicle model name

                -- Disable vehicle from repairing with extras
                SetVehicleAutoRepairDisabled(vehicle, true)

                -- Enable siren but mute it
                SetVehicleSiren(vehicle, true)
                SetVehicleHasMutedSirens(vehicle, true)

                -- Get the pattern ID for this vehicle
                local modelName = GetDisplayNameFromVehicleModel(GetEntityModel(vehicle))
                local patternID = nil
                for _, vehicleConfig in ipairs(Config.Vehicles) do
                    if vehicleConfig.Model == modelName then
                        patternID = vehicleConfig.Pattern
                        --break
                    end
                end
                if patternID then
                    print("Pattern ID for this vehicle: " .. patternID)
                    local pattern = Config.Patterns[patternID]
                    print("FirstFlash extras: " .. table.concat(pattern.FirstFlash, ", "))
                    print("SecondFlash extras: " .. table.concat(pattern.SecondFlash, ", "))

                    -- Enable Extras for First Flash
                    for _, extraIndex in ipairs(pattern.FirstFlash) do
                        SetVehicleExtra(vehicle, extraIndex, 0)
                    end

                    -- Flash Delay
                    Citizen.Wait(250) -- Adjust the delay as needed

                    -- Disable Extras for stage 1
                    for _, extraIndex in ipairs(pattern.FirstFlash) do
                        SetVehicleExtra(vehicle, extraIndex, 1)
                    end

                    -- Enable Extras for Second Flash
                    for _, extraIndex in ipairs(pattern.SecondFlash) do
                        SetVehicleExtra(vehicle, extraIndex, 0)
                    end

                    -- Flash Delay
                    Citizen.Wait(250) -- Adjust the delay as needed

                    -- Disable Extras for stage 2
                    for _, extraIndex in ipairs(pattern.SecondFlash) do
                        SetVehicleExtra(vehicle, extraIndex, 1)
                    end
                else
                    print("No pattern found for this vehicle")
                end
            end
        else
            local ped = PlayerPedId()
            local vehicle = GetVehiclePedIsUsing(ped)
            if vehicle ~= 0 then
                SetVehicleExtra(vehicle, 1, 1)
                SetVehicleExtra(vehicle, 3, 1)
                SetVehicleExtra(vehicle, 7, 1)
                SetVehicleExtra(vehicle, 2, 1)
                SetVehicleExtra(vehicle, 4, 1)
                SetVehicleExtra(vehicle, 9, 1)
            end
        end
    end
end)

function EnablePrimaryStage(vehicleConfig)
	while true do
		Citizen.Wait(1)
		if LightsActivated then
			if IsPedInAnyVehicle(GetPlayerPed(-1)) then
				local ped = PlayerPedId()
				local vehicle = GetVehiclePedIsUsing(ped)
	
				-- Disable vehicle from repairing with extras
				SetVehicleAutoRepairDisabled(vehicle, true)
	
				-- Enable siren but mute it
				SetVehicleSiren(vehicle, true)
				SetVehicleHasMutedSirens(vehicle, true)
	
				if vehicleConfig then
					local pattern = Config.Patterns[vehicleConfig.Pattern]
					print(pattern)
	
					if pattern then
						for _, stage in ipairs(pattern.Stages) do
							for _, extraIndex in ipairs(stage.Extras) do
								SetVehicleExtra(vehicle, extraIndex, 0)
							end
	
							-- Flash delay
							Citizen.Wait(pattern.FlashDelay)
	
							-- Disable extras for this stage
							for _, extraIndex in ipairs(stage.Extras) do
								SetVehicleExtra(vehicle, extraIndex, 1)
							end
						end
					end
				end
			end
		end
	end
end