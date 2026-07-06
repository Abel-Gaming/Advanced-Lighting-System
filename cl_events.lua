----- PRIMARY SIREN -----
-- Sound playback is local to each client, so this DOES need to travel over
-- the network - but as a netId (safe across clients), not a raw entity
-- handle. `soundId` is now actually used (the original referenced an
-- undefined global, so no sound ever played).
RegisterNetEvent('ALS:PlayPrimarySirenClient')
AddEventHandler('ALS:PlayPrimarySirenClient', function(netId)
    local vehicle = GetVehicleFromNetId(netId)
    if not vehicle then return end

    local soundId = GetSoundId()
    activeSounds[netId] = soundId

    SetVehicleHasMutedSirens(vehicle, true)
    SetVehicleSiren(vehicle, true)

    if Config.UseWMServerSirens then
        PlaySoundFromEntity(soundId, 'SIREN_ALPHA', vehicle, 'DLC_WMSIRENS_SOUNDSET', 0, 0)
    else
        PlaySoundFromEntity(soundId, 'VEHICLES_HORNS_SIREN_1', vehicle, 0, 0, 0)
    end
end)

RegisterNetEvent('ALS:StopPrimarySirenClient')
AddEventHandler('ALS:StopPrimarySirenClient', function(netId)
    local soundId = activeSounds[netId]
    if soundId then
        StopSound(soundId)
        ReleaseSoundId(soundId)
        activeSounds[netId] = nil
    end
end)

----- SECONDARY SIREN -----
RegisterNetEvent('ALS:PlaySecondarySirenClient')
AddEventHandler('ALS:PlaySecondarySirenClient', function(netId)
    local vehicle = GetVehicleFromNetId(netId)
    if not vehicle then return end

    local soundId = GetSoundId()
    activeSounds[netId] = soundId

    SetVehicleHasMutedSirens(vehicle, true)
    SetVehicleSiren(vehicle, true)

    if Config.UseWMServerSirens then
        PlaySoundFromEntity(soundId, 'SIREN_DELTA', vehicle, 'DLC_WMSIRENS_SOUNDSET', 0, 0)
    else
        PlaySoundFromEntity(soundId, 'VEHICLES_HORNS_SIREN_2', vehicle, 0, 0, 0)
    end
end)

RegisterNetEvent('ALS:StopSecondarySirenClient')
AddEventHandler('ALS:StopSecondarySirenClient', function(netId)
    local soundId = activeSounds[netId]
    if soundId then
        StopSound(soundId)
        ReleaseSoundId(soundId)
        activeSounds[netId] = nil
    end
end)

-- NOTE ON LIGHTS: 'ALS:TogglePrimaryLights' / 'ALS:ToggleSecondaryLights' /
-- 'ALS:ToggleWarningLights' / 'ALS:DisableLights' have been removed here.
-- The old script broadcast these to every client with a raw entity handle
-- (TriggerClientEvent(..., -1, vehicle, ...)), which is not safe - on
-- another player's machine that handle can point to a different entity or
-- nothing at all. This was the main source of the random/broken light
-- behaviour. Vehicle extras sync automatically as part of normal vehicle
-- network sync when set by the controlling (driving) client, so lights are
-- now handled purely locally in cl_main.lua / cl_functions.lua - no
-- network relay needed or wanted.

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
-- This one is fine to keep as a plain local loop: each client resolves its
-- own local list of visible peds/vehicles via GetActivePlayers(), it never
-- passes an entity handle across the network.
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
