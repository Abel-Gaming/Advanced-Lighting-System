----- SIREN SOUND HELPERS -----
-- Sound playback is local to each client, so this DOES need to travel over
-- the network - but as a netId (safe across clients), not a raw entity
-- handle.
local function playSirenSound(netId, vehicle, soundName)
    local soundId = GetSoundId()
    activeSounds[netId] = soundId

    if Config.UseWMServerSirens then
        PlaySoundFromEntity(soundId, soundName, vehicle, 'DLC_WMSIRENS_SOUNDSET', 0, 0)
    else
        PlaySoundFromEntity(soundId, soundName, vehicle, 0, 0, 0)
    end
end

local function stopSirenSound(netId)
    local soundId = activeSounds[netId]
    if soundId then
        StopSound(soundId)
        ReleaseSoundId(soundId)
        activeSounds[netId] = nil
    end
end

----- PRIMARY SIREN -----
RegisterNetEvent('ALS:PlayPrimarySirenClient')
AddEventHandler('ALS:PlayPrimarySirenClient', function(netId)
    local vehicle = GetVehicleFromNetId(netId)
    if not vehicle then return end

    SetVehicleHasMutedSirens(vehicle, true)
    SetVehicleSiren(vehicle, true)
    playSirenSound(netId, vehicle, Config.SirenTones.Primary.Normal)
end)

RegisterNetEvent('ALS:StopPrimarySirenClient')
AddEventHandler('ALS:StopPrimarySirenClient', function(netId)
    stopSirenSound(netId)
end)

----- SECONDARY SIREN -----
RegisterNetEvent('ALS:PlaySecondarySirenClient')
AddEventHandler('ALS:PlaySecondarySirenClient', function(netId)
    local vehicle = GetVehicleFromNetId(netId)
    if not vehicle then return end

    SetVehicleHasMutedSirens(vehicle, true)
    SetVehicleSiren(vehicle, true)
    playSirenSound(netId, vehicle, Config.SirenTones.Secondary.Normal)
end)

RegisterNetEvent('ALS:StopSecondarySirenClient')
AddEventHandler('ALS:StopSecondarySirenClient', function(netId)
    stopSirenSound(netId)
end)

----- SIREN TONE SWITCH (hold-to-change-tone, like vanilla GTA) -----
-- Only fires while a siren is actually playing for this vehicle (guarded
-- by activeSounds[netId] below), so a stray/late event can't start a sound
-- out of nowhere.
RegisterNetEvent('ALS:SetSirenToneClient')
AddEventHandler('ALS:SetSirenToneClient', function(netId, sirenType, alt)
    if not activeSounds[netId] then return end

    local vehicle = GetVehicleFromNetId(netId)
    if not vehicle then return end

    local toneSet = Config.SirenTones[sirenType]
    if not toneSet then return end

    stopSirenSound(netId)
    playSirenSound(netId, vehicle, alt and toneSet.Alt or toneSet.Normal)
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

----- FAST EXTRAS PUSH (fixes laggy/choppy lights on other players' screens) -----
-- timeoutMs=0 here on purpose: if this vehicle isn't streamed in for us
-- yet, there's nothing to draw anyway, so don't block this event handler
-- waiting on it - just skip and let the next push (a few hundred ms later)
-- pick it up once it streams in.
RegisterNetEvent('ALS:SetExtrasClient')
AddEventHandler('ALS:SetExtrasClient', function(netId, extraIds, state)
    local vehicle = GetVehicleFromNetId(netId, 0)
    if not vehicle then return end
    for _, extraIndex in ipairs(extraIds) do
        ToggleExtra(vehicle, extraIndex, state)
    end
end)

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
