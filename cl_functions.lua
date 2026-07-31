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

-- Tracks which vehicles currently have an environment light running, keyed by vehicle handle, so the draw loop knows when to stop.
ActiveEnvironmentLights = {}

ALL_LIGHT_EXTRA_IDS = {1, 2, 3, 4, 5, 6, 7, 8, 9}

function IsShowingEmergencyLights(vehicle, extraIds)
    if not DoesEntityExist(vehicle) then return false end
    for _, extraId in ipairs(extraIds or ALL_LIGHT_EXTRA_IDS) do
        if DoesExtraExist(vehicle, extraId) and IsVehicleExtraTurnedOn(vehicle, extraId) then
            return true
        end
    end
    return false
end

function CreateEnvironmentLight(vehicle, light, offset, color, extraIds)
    local boneIndex = GetEntityBoneIndexByName(vehicle, light)
    if boneIndex == -1 then
        print("Error: Bone '" .. light .. "' not found on vehicle.")
        return
    end

    local rgb = { 255, 255, 255 } -- Default color: white
    local range = Config.ELSRange or 50.0
    local intensity = Config.ELSIntensity or 1.0
    local shadow = 0
    local warnedBadPosition = false

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
            if IsShowingEmergencyLights(vehicle, extraIds) then
                local boneWorldPos = GetWorldPositionOfEntityBone(vehicle, boneIndex)
                local right, forward, up, _ = GetEntityMatrix(vehicle)
                local worldOffset = (right * offset.x) + (forward * offset.y) + (up * offset.z)
                local position = boneWorldPos + worldOffset
                local vehiclePos = GetEntityCoords(vehicle)
                if #(position - vehiclePos) <= 10.0 then
                    DrawLightWithRangeAndShadow(
                        position.x, position.y, position.z,
                        rgb[1], rgb[2], rgb[3],
                        range, intensity, shadow
                    )
                elseif not warnedBadPosition then
                    warnedBadPosition = true
                    print(("Warning: environment light on bone '%s' computed a position %.1fm from the vehicle - skipping draw. Check that this bone exists in the right place on this vehicle model."):format(light, #(position - vehiclePos)))
                end
            end
            Citizen.Wait(0)
        end
        ActiveEnvironmentLights[vehicle] = nil
    end)
end

function StopEnvironmentLight(vehicle)
    ActiveEnvironmentLights[vehicle] = nil
end

function StartEnvironmentLights(vehicle, vehicleConfig)
    local lights = (vehicleConfig and vehicleConfig.EnvironmentLights) or Config.DefaultEnvironmentLights
    for _, def in ipairs(lights) do
        CreateEnvironmentLight(vehicle, def.Bone, def.Offset, def.Color, def.Extras)
    end
end

----- SIREN STATE (entity state bags) -----
function SetVehicleSirenState(vehicle, tone)
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then return end
    Entity(vehicle).state:set('elsSiren', { active = true, tone = tone }, true)
end

function ClearVehicleSirenState(vehicle)
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then return end
    Entity(vehicle).state:set('elsSiren', nil, true)
end

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
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then return end
    SetVehicleSiren(vehicle, false)
    for extraId = 0, 20 do
        if DoesExtraExist(vehicle, extraId) then
            SetVehicleExtra(vehicle, extraId, 1)
        end
    end
end

local ActivePatternRunners = {}

local function stageKey(vehicle, stageName)
    return vehicle .. ':' .. stageName
end

function RunPatternStage(vehicle, stageName, patternId)
    local key = stageKey(vehicle, stageName)
    if ActivePatternRunners[key] then return end -- already running for this vehicle/stage

    local pattern = Config.Patterns[patternId]
    local stages = pattern and pattern[stageName]
    if not pattern or not stages then return end

    ActivePatternRunners[key] = true

    Citizen.CreateThread(function()
        while ActivePatternRunners[key] and DoesEntityExist(vehicle) do
            SetVehicleEngineOn(vehicle, true, true, false)

            for _, stage in ipairs(stages) do
                if not ActivePatternRunners[key] or not DoesEntityExist(vehicle) then break end

                for _, extraIndex in ipairs(stage.Extras) do
                    ToggleExtra(vehicle, extraIndex, true)
                end

                Citizen.Wait(pattern.FlashDelay)

                for _, extraIndex in ipairs(stage.Extras) do
                    ToggleExtra(vehicle, extraIndex, false)
                end
            end
        end
        ActivePatternRunners[key] = nil
    end)
end

function StopPatternStage(vehicle, stageName)
    ActivePatternRunners[stageKey(vehicle, stageName)] = nil
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

function IsSirenActive()
	return ActiveSirenTone ~= nil
end

function UpdateVehicles()
    while true do
        TriggerEvent('ALS:GetPlayersAndVehicles')
        Citizen.Wait(Config.VehicleUpdateTime * 1000)
    end
end
