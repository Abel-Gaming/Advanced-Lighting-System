----- PRIMARY SIREN -----
RegisterNetEvent('ALS:PlayPrimarySirenClient')
AddEventHandler('ALS:PlayPrimarySirenClient', function(vehicle, soundID)
    SetVehicleSiren(vehicle, true)
end)

RegisterNetEvent('ALS:StopPrimarySirenClient')
AddEventHandler('ALS:StopPrimarySirenClient', function(vehicle)
    SetVehicleSiren(vehicle, false)
end)

----- SECONDARY SIREN -----
RegisterNetEvent('ALS:PlaySecondarySirenClient')
AddEventHandler('ALS:PlaySecondarySirenClient', function(vehicle)
    local soundId = GetSoundId()
    if Config.EnableDebugging then
        print('Starting Siren: ' .. soundId)
        print(vehicle)
    end
    PlaySoundFromEntity(soundId, 'SIREN_DELTA', vehicle, 'DLC_WMSIRENS_SOUNDSET', 0, 0)
    activeSounds[vehicle] = soundId
end)

RegisterNetEvent('ALS:StopSecondarySirenClient')
AddEventHandler('ALS:StopSecondarySirenClient', function(vehicle)
    local soundId = activeSounds[vehicle]
    if Config.EnableDebugging then
        print('Stopping Siren: ' .. soundId)
        print(vehicle)
    end
    if soundId then
        StopSound(soundId)
        ReleaseSoundId(soundId)
        activeSounds[vehicle] = nil
    end
end)

----- PRIMARY LIGHTS -----
RegisterNetEvent('ALS:TogglePrimaryLights')
AddEventHandler('ALS:TogglePrimaryLights', function(vehicle, vehicleConfig)
    Citizen.CreateThread(function()
        EnablePrimaryStage(vehicle, vehicleConfig)
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