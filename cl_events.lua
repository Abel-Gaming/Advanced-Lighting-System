AddStateBagChangeHandler('elsSiren', nil, function(bagName, _key, value)
    local vehicle = GetEntityFromStateBagName(bagName)
    if not vehicle or not DoesEntityExist(vehicle) then return end

    local existingSoundId = activeSounds[vehicle]
    if existingSoundId then
        StopSound(existingSoundId)
        ReleaseSoundId(existingSoundId)
        activeSounds[vehicle] = nil
    end

    if not value or not value.active then return end

    local soundName = Config.SirenTones[value.tone]
    if not soundName then return end

    local soundId = GetSoundId()
    activeSounds[vehicle] = soundId

    SetVehicleHasMutedSirens(vehicle, true)
    SetVehicleSiren(vehicle, true)

    if Config.UseWMServerSirens then
        PlaySoundFromEntity(soundId, soundName, vehicle, 'DLC_WMSIRENS_SOUNDSET', 0, 0)
    else
        PlaySoundFromEntity(soundId, soundName, vehicle, 0, 0, 0)
    end
end)

local function handleLightStageBag(stageName)
    return function(bagName, _key, value)
        local vehicle = GetEntityFromStateBagName(bagName)
        if not vehicle or not DoesEntityExist(vehicle) then return end

        if value and value.patternId then
            RunPatternStage(vehicle, stageName, value.patternId)
        else
            StopPatternStage(vehicle, stageName)
        end
    end
end

AddStateBagChangeHandler('elsPrimary', nil, handleLightStageBag('Primary'))
AddStateBagChangeHandler('elsSecondary', nil, handleLightStageBag('Secondary'))
AddStateBagChangeHandler('elsWarning', nil, handleLightStageBag('Warning'))

----- TOGGLE A SINGLE EXTRA (manual/panel use) -----
RegisterNetEvent('ALS:toggleExtra')
AddEventHandler('ALS:toggleExtra', function(vehicle, extra)
    if not vehicle or not extra then return end
    extra = tonumber(extra)
    if not extra or not DoesExtraExist(vehicle, extra) then return end
    local isOn = IsVehicleExtraTurnedOn(vehicle, extra)
    ToggleExtra(vehicle, extra, not isOn)
end)

----- DISABLE AUTO-REPAIR ON VISIBLE EMERGENCY VEHICLES -----
RegisterNetEvent('ALS:GetPlayersAndVehicles')
AddEventHandler('ALS:GetPlayersAndVehicles', function()
    for _, playerId in ipairs(GetActivePlayers()) do
        local ped = GetPlayerPed(playerId)
        if IsPedInAnyVehicle(ped, false) then
            local vehicle = GetVehiclePedIsIn(ped, false)
            SetVehicleAutoRepairDisabled(vehicle, true)
        end
    end
end)
