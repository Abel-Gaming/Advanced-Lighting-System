-- State bag handlers only update local Lua state. All the actual drawing
-- and extra toggling happens in the single loop in cl_functions.lua.
-- If the vehicle hasn't streamed in yet, the 1s sync scan picks it up.

local function bagVehicle(bagName)
    local vehicle = GetEntityFromStateBagName(bagName)
    if vehicle == 0 or not DoesEntityExist(vehicle) then return nil end
    return vehicle
end

AddStateBagChangeHandler('elsSiren', nil, function(bagName, _key, value)
    local vehicle = bagVehicle(bagName)
    if not vehicle then return end
    local tone = (value and value.active) and value.tone or nil
    if tone ~= ALSSirens[vehicle] then
        ApplyVehicleSiren(vehicle, tone)
    end
end)

local function handleLightStageBag(stageName)
    return function(bagName, _key, value)
        local vehicle = bagVehicle(bagName)
        if not vehicle then return end
        SetVehicleStage(vehicle, stageName, value and value.patternId or nil)
    end
end

AddStateBagChangeHandler('elsPrimary', nil, handleLightStageBag('Primary'))
AddStateBagChangeHandler('elsSecondary', nil, handleLightStageBag('Secondary'))
AddStateBagChangeHandler('elsWarning', nil, handleLightStageBag('Warning'))

----- TOGGLE A SINGLE EXTRA (manual/panel use) -----
-- Takes a network ID (entity handles are different on every client).
RegisterNetEvent('ALS:toggleExtra')
AddEventHandler('ALS:toggleExtra', function(netId, extra)
    if not netId or not extra then return end
    local vehicle = NetworkDoesNetworkIdExist(netId) and NetToVeh(netId) or 0
    extra = tonumber(extra)
    if vehicle == 0 or not extra or not DoesExtraExist(vehicle, extra) then return end
    local isOn = IsVehicleExtraTurnedOn(vehicle, extra)
    ToggleExtra(vehicle, extra, not isOn)
end)

----- DISABLE AUTO-REPAIR ON VISIBLE EMERGENCY VEHICLES -----
AddEventHandler('ALS:GetPlayersAndVehicles', function()
    for _, playerId in ipairs(GetActivePlayers()) do
        local ped = GetPlayerPed(playerId)
        if IsPedInAnyVehicle(ped, false) then
            local vehicle = GetVehiclePedIsIn(ped, false)
            SetVehicleAutoRepairDisabled(vehicle, true)
        end
    end
end)

----- CLEAN UP SOUNDS IF THE RESOURCE IS RESTARTED -----
AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    for vehicle in pairs(activeSounds) do
        StopVehicleSirenSound(vehicle)
    end
end)
