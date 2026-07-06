function getClosestRoad(coords)
    local _, closestRoad, _, _ = GetClosestRoad(coords.x, coords.y, coords.z, 1, 1)
    return closestRoad
end

function GetHeadlightStatus(vehicle)
    local _, lightsOn, _ = GetVehicleLightsState(vehicle)
    return lightsOn
end

function GetHeadlightHighBeamStatus(vehicle)
    local _, _, highbeamsOn = GetVehicleLightsState(vehicle)
    return highbeamsOn
end

function spawnObject(objectName, coords)
    local modelHash = GetHashKey(objectName)

    RequestModel(modelHash)
    while not HasModelLoaded(modelHash) do
        Citizen.Wait(0)
    end

    local object = CreateObject(modelHash, coords.x, coords.y, coords.z, true, true, true)
    SetModelAsNoLongerNeeded(modelHash)

    return object
end

function ErrorMessage(errorMessage)
	SetNotificationTextEntry('STRING')
	AddTextComponentSubstringPlayerName('~r~[ERROR]~w~ ' .. errorMessage)
	DrawNotification(false, true)
end

function InfoMessage(message)
	SetNotificationTextEntry('STRING')
	AddTextComponentSubstringPlayerName('~y~[INFO]~w~ ' .. message)
	DrawNotification(false, true)
end

function SuccessMessage(successMessage)
	SetNotificationTextEntry('STRING')
	AddTextComponentSubstringPlayerName('~g~[SUCCESS]~w~ ' .. successMessage)
	DrawNotification(false, true)
end

function sendChatMessageInfo(message)
	TriggerEvent("chatMessage", "", {0, 0, 0}, "^3[INFO] ^7" .. message)
end

function sendChatMessageError(message)
	TriggerEvent("chatMessage", "", {0, 0, 0}, "^8[ERROR] ^7" .. message)
end

function sendChatMessageNormal(message)
	TriggerEvent("chatMessage", "", {0, 0, 0}, "^7" .. message)
end

-- Tracks which vehicles currently have an environment light running, keyed
-- by vehicle handle, so the draw loop knows when to stop.
ActiveEnvironmentLights = {}

-- DrawLightWithRangeAndShadow only persists for a single frame, so it has
-- to be re-issued every tick for as long as the light should stay visible -
-- calling it once (as the original did) draws it for one frame and it's
-- gone. This also transforms `offset` through the vehicle's current
-- rotation each frame (via GetOffsetFromEntityInWorldCoords), instead of
-- just adding it in world space, so the light stays in the same relative
-- spot on the car as it turns.
function CreateEnvironmentLight(vehicle, light, offset, color)
    local boneIndex = GetEntityBoneIndexByName(vehicle, light)
    if boneIndex == -1 then
        print("Error: Bone '" .. light .. "' not found on vehicle.")
        return
    end

    local rgb = { 255, 255, 255 } -- Default color: white
    local range = 10.0
    local intensity = 5.0
    local shadow = 1

    color = string.lower(color)
    if color == 'blue' then
        rgb = { 0, 0, 255 }
    elseif color == 'red' then
        rgb = { 255, 0, 0 }
    elseif color == 'green' then
        rgb = { 0, 255, 0 }
    elseif color == 'amber' then
        rgb = { 255, 194, 0 }
    end

    ActiveEnvironmentLights[vehicle] = true

    Citizen.CreateThread(function()
        while ActiveEnvironmentLights[vehicle] and DoesEntityExist(vehicle) do
            -- GetWorldPositionOfEntityBone gives us the bone's real world
            -- position. `offset` is meant to be a small vehicle-relative
            -- nudge from that bone, so we rotate just the offset by the
            -- vehicle's current heading (via its matrix) and add it on -
            -- rather than feeding world coordinates into a native that
            -- expects a local offset, which is what produced a position
            -- nowhere near the vehicle before.
            local boneWorldPos = GetWorldPositionOfEntityBone(vehicle, boneIndex)
            local right, forward, up, _ = GetEntityMatrix(vehicle)
            local worldOffset = (right * offset.x) + (forward * offset.y) + (up * offset.z)
            local position = boneWorldPos + worldOffset

            DrawLightWithRangeAndShadow(
                position.x, position.y, position.z,
                rgb[1], rgb[2], rgb[3],
                range, intensity, shadow
            )
            Citizen.Wait(0)
        end
        ActiveEnvironmentLights[vehicle] = nil
    end)
end

function StopEnvironmentLight(vehicle)
    ActiveEnvironmentLights[vehicle] = nil
end

-- Starts every environment light configured for this vehicle (its own
-- EnvironmentLights list, or Config.DefaultEnvironmentLights if it doesn't
-- have one). Safe to call repeatedly; callers should check
-- ActiveEnvironmentLights[vehicle] first to avoid stacking duplicate
-- draw threads.
function StartEnvironmentLights(vehicle, vehicleConfig)
    local lights = (vehicleConfig and vehicleConfig.EnvironmentLights) or Config.DefaultEnvironmentLights
    for _, def in ipairs(lights) do
        CreateEnvironmentLight(vehicle, def.Bone, def.Offset, def.Color)
    end
end

----- NETWORK ID HELPERS -----
-- Entity handles are LOCAL to each client's game instance - they are not
-- safe to send over the network, because the same number can point to a
-- different entity (or nothing at all) on another player's machine. Any
-- vehicle reference that needs to travel client -> server -> client (e.g.
-- for siren audio) must be converted to/from a network id instead.
function GetVehicleNetId(vehicle)
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then
        return nil
    end
    return NetworkGetNetworkIdFromEntity(vehicle)
end

function GetVehicleFromNetId(netId, timeoutMs)
    if not netId then return nil end
    timeoutMs = timeoutMs or 2000
    local start = GetGameTimer()
    while not NetworkDoesNetworkIdExist(netId) and (GetGameTimer() - start) < timeoutMs do
        Citizen.Wait(0)
    end
    if not NetworkDoesNetworkIdExist(netId) then return nil end
    return NetworkGetEntityFromNetworkId(netId)
end

----- EXTRAS -----
-- state = true  -> extra ON  (native value 0)
-- state = false -> extra OFF (native value 1)
-- (Previously this relied on the fact that 0 is "truthy" in Lua, which
-- happened to work but was extremely easy to misuse - made explicit here.)
function ToggleExtra(vehicle, extra, state)
    if not DoesExtraExist(vehicle, extra) then return end
    SetVehicleAutoRepairDisabled(vehicle, true)
    SetVehicleExtra(vehicle, extra, state and 0 or 1)
end

function ToggleMisc(vehicle, misc, toggle)
    SetVehicleModKit(vehicle, 0)
    SetVehicleMod(vehicle, misc, toggle, false)
end

function DisableActiveExtras(vehicle)
    -- Guarded against nil/0/invalid entities - previously this was called
    -- with no argument at all on resource start and would try to iterate
    -- extras on a nil vehicle.
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then return end
    SetVehicleSiren(vehicle, false)
    for extraId = 0, 20 do
        if DoesExtraExist(vehicle, extraId) then
            SetVehicleExtra(vehicle, extraId, 1)
        end
    end
end

----- LIGHT PATTERNS -----
-- These only ever run on the client currently driving the vehicle. Vehicle
-- extras are part of the game's normal vehicle network sync, so other
-- players see the changes automatically - there is no need (and it was not
-- safe, see the net-id note above) to re-broadcast every extra toggle to
-- every other client the way the old script did for Secondary/Warning.
local function runStagePattern(vehicle, pattern, stages, isStillActiveFn)
    while isStillActiveFn() do
        if not DoesEntityExist(vehicle) then return end
        SetVehicleEngineOn(vehicle, true, true, false)

        for _, stage in ipairs(stages) do
            if not isStillActiveFn() or not DoesEntityExist(vehicle) then return end

            for _, extraIndex in ipairs(stage.Extras) do
                ToggleExtra(vehicle, extraIndex, true)
            end

            Citizen.Wait(pattern.FlashDelay)

            for _, extraIndex in ipairs(stage.Extras) do
                ToggleExtra(vehicle, extraIndex, false)
            end
        end
    end
end

function EnablePrimaryStage(vehicle, vehicleConfig)
    local pattern = Config.Patterns[vehicleConfig.Pattern]
    if not pattern then return end
    runStagePattern(vehicle, pattern, pattern.Primary, function() return PrimaryLightsActivated end)
end

function EnableSecondaryStage(vehicle, vehicleConfig)
    local pattern = Config.Patterns[vehicleConfig.Pattern]
    if not pattern then return end
    runStagePattern(vehicle, pattern, pattern.Secondary, function() return SecondaryLightsActivated end)
end

function EnableWarningStage(vehicle, vehicleConfig)
    local pattern = Config.Patterns[vehicleConfig.Pattern]
    if not pattern then return end
    runStagePattern(vehicle, pattern, pattern.Warning, function() return WarningLightsActivated end)
end

----- UI DRAWING (unchanged, not buggy) -----
function _DrawRect(x, y, width, height, r, g, b, a, ya)
    SetUiLayer(ya)
    DrawRect(x, y, width, height, r, g, b, a)
end

function Draw(text, r, g, b, alpha, x, y, width, height, ya, center, font)
    SetTextColour(r, g, b, alpha)
    SetTextFont(font)
    SetTextScale(width, height)
    SetTextWrap(0.0, 1.0)
    SetTextCentre(center)
    SetTextDropshadow(0, 0, 0, 0, 0)
    SetTextEdge(1, 0, 0, 0, 205)
    BeginTextCommandDisplayText("STRING")
    AddTextComponentSubstringPlayerName(text)
    SetUiLayer(ya)
    EndTextCommandDisplayText(x, y)
end

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

function UpdateVehicles()
    while true do
        TriggerEvent('ALS:GetPlayersAndVehicles')
        Citizen.Wait(Config.VehicleUpdateTime * 1000)
    end
end
