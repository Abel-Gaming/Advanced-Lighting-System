----- PRIMARY SIREN -----
RegisterNetEvent('ALS:PlayPrimarySirenClient')
AddEventHandler('ALS:PlayPrimarySirenClient', function(vehicle)
    if Config.UseWMServerSirens then
        -- Get the sound ID
        activeSounds[vehicle] = GetSoundId()

        -- Play sound
        PlaySoundFromEntity(soundId, 'SIREN_ALPHA', vehicle, 'DLC_WMSIRENS_SOUNDSET', 0, 0)

        -- Mute the native siren
        SetVehicleHasMutedSirens(vehicle, 0)
        toggleSirenMute(vehicle, 0)

        -- Enable emergency mode
        SetVehicleSiren(vehicle, 0)
    else
        -- Get the sound ID
        activeSounds[vehicle] = GetSoundId()

        -- Play sound
        PlaySoundFromEntity(soundId, 'VEHICLES_HORNS_SIREN_1', vehicle, 0, 0, 0)

        -- Set native siren to be muted
        SetVehicleHasMutedSirens(vehicle, true)
        toggleSirenMute(vehicle, true)

        -- Enable emergency mode
        SetVehicleSiren(vehicle, true)
    end
end)

RegisterNetEvent('ALS:StopPrimarySirenClient')
AddEventHandler('ALS:StopPrimarySirenClient', function(vehicle)
    if Config.UseWMServerSirens then
        local soundId = activeSounds[vehicle]
        StopSound(soundId)
        ReleaseSoundId(soundId)
        activeSounds[vehicle] = nil
    else
        StopSound(activeSounds[vehicle])
        ReleaseSoundId(activeSounds[vehicle])
        activeSounds[vehicle] = nil
    end 
end)

----- SECONDARY SIREN -----
RegisterNetEvent('ALS:PlaySecondarySirenClient')
AddEventHandler('ALS:PlaySecondarySirenClient', function(vehicle)
    if Config.UseWMServerSirens then
        SetVehicleHasMutedSirens(vehicle, true)
        toggleSirenMute(vehicle, true)
        SetVehicleSiren(vehicle, true)
        activeSounds[vehicle] = GetSoundId()
        PlaySoundFromEntity(soundId, 'SIREN_DELTA', vehicle, 'DLC_WMSIRENS_SOUNDSET', 0, 0)
    else
        -- Get the sound ID
        activeSounds[vehicle] = GetSoundId()

        -- Play sound
        PlaySoundFromEntity(soundId, 'VEHICLES_HORNS_SIREN_2', vehicle, 0, 0, 0)

        -- Set native siren to be muted
        SetVehicleHasMutedSirens(vehicle, true)

        -- Enable emergency mode
        SetVehicleSiren(vehicle, true)
    end

end)

RegisterNetEvent('ALS:StopSecondarySirenClient')
AddEventHandler('ALS:StopSecondarySirenClient', function(vehicle)
    if Config.UseWMServerSirens then
        local soundId = activeSounds[vehicle]
        if soundId then
            StopSound(soundId)
            ReleaseSoundId(soundId)
            activeSounds[vehicle] = nil
        end
    else
        StopSound(activeSounds[vehicle])
        ReleaseSoundId(activeSounds[vehicle])
        activeSounds[vehicle] = nil
    end
end)

----- PRIMARY LIGHTS -----
RegisterNetEvent('ALS:TogglePrimaryLights')
AddEventHandler('ALS:TogglePrimaryLights', function(vehicle, vehicleConfig, vehicleData)
    Citizen.CreateThread(function()
        TogglePrimaryStage(vehicle, vehicleConfig, vehicleData)
    end)
end)

----- SECONDARY LIGHTS -----
RegisterNetEvent('ALS:ToggleSecondaryLights')
AddEventHandler('ALS:ToggleSecondaryLights', function(vehicle, vehicleConfig)
    Citizen.CreateThread(function()
        EnableSecondaryStage(vehicle, vehicleConfig)
    end)
end)

----- WARNING LIGHTS -----
RegisterNetEvent('ALS:ToggleWarningLights')
AddEventHandler('ALS:ToggleWarningLights', function(vehicle, vehicleConfig)
    Citizen.CreateThread(function()
        EnableWarningStage(vehicle, vehicleConfig)
    end)
end)

----- DISABLE EMERGENCY LIGHTS -----
RegisterNetEvent('ALS:DisableLights')
AddEventHandler('ALS:DisableLights', function(vehicle)
    DisableActiveExtras(vehicle)
end)

----- TOGGLE EXTRAS -----
RegisterNetEvent('ALS:toggleExtra')
AddEventHandler('ALS:toggleExtra', function(vehicle, extra)
    if not vehicle or not extra then
        CancelEvent()
        return
    end
    extra = tonumber(extra) or -1
    local model = GetDisplayNameFromVehicleModel(GetEntityModel(vehicle))
    if not DoesExtraExist(vehicle, extra) then
        print('Extra ' .. extra .. ' does not exist on your ' .. model .. '!')
        CancelEvent()
        return
    end
    local toggle = IsVehicleExtraTurnedOn(vehicle, extra)
    SetVehicleAutoRepairDisabled(vehicle, true)
    SetVehicleExtra(vehicle, extra, toggle)
end)

----- GET PLAYERS AND EXTRAS -----
RegisterNetEvent('ALS:GetPlayersAndVehicles')
AddEventHandler('ALS:GetPlayersAndVehicles', function()
    local players = GetActivePlayers()
    
    for _, playerId in ipairs(players) do
        local ped = GetPlayerPed(playerId)
        
        if IsPedInAnyVehicle(ped, false) then
            local vehicle = GetVehiclePedIsIn(ped, false)
            local vehicleModel = GetEntityModel(vehicle)
            local vehicleName = GetDisplayNameFromVehicleModel(vehicleModel)
            SetVehicleAutoRepairDisabled(vehicle, true)
        end
    end
end)

----- DISABLE AUTO REPAIR AND ADD VEHICLE TO VEHICLES LIST -----
RegisterNetEvent('ALS:PlayerEnteredVehicle')
AddEventHandler('ALS:PlayerEnteredVehicle', function(playerID, vehicle, vehicleSeat, vehicleDisplayName)
    if vehicleSeat == -1 then
        if GetVehicleClass(vehicle) == 18 then
            if not isInTable(activeVehicles, vehicle) then
                local vehicleData = {
                    entity = vehicle,
                    seat = vehicleSeat,
                    displayName = vehicleDisplayName,
                    owner = playerID,
                    PrimaryLights = false,
                    SecondaryLights = false,
                    WarningLights = false,
                    PrimarySiren = false,
                    SecondrySiren = false
                }
                table.insert(activeVehicles, vehicleData)
                SetVehicleAutoRepairDisabled(vehicle, true)
            end
        end
    end 
end)