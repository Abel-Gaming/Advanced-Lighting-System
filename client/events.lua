----- PRIMARY SIREN -----
RegisterNetEvent('ALS:PlayPrimarySirenClient')
AddEventHandler('ALS:PlayPrimarySirenClient', function(vehicle)
    local soundId = GetSoundId()
    if Config.EnableDebugging then
        print('Starting Siren: ' .. soundId)
        print(vehicle)
    end
    PlaySoundFromEntity(soundId, 'SIREN_ALPHA', vehicle, 'DLC_WMSIRENS_SOUNDSET', 0, 0)
    activeSounds[vehicle] = soundId
end)

RegisterNetEvent('ALS:StopPrimarySirenClient')
AddEventHandler('ALS:StopPrimarySirenClient', function(vehicle)
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
    print(soundId)
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