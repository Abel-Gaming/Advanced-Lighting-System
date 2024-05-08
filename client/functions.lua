function getClosestRoad(coords)
    local _, closestRoad, _, _ = GetClosestRoad(coords.x, coords.y, coords.z, 1, 1)
    return closestRoad
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

function sendChatMessage(message)
	TriggerEvent("chatMessage", "", {0, 0, 0}, "^3[REPORT] ^2" .. message)
end

function sendChatMessageNormal(message)
	TriggerEvent("chatMessage", "", {0, 0, 0}, "^7" .. message)
end

function ToggleExtra(vehicle, extra, toggle)
    local value = toggle and 0 or 1
    SetVehicleAutoRepairDisabled(vehicle, true)
    SetVehicleExtra(vehicle, extra, value)
end

function CreateEnviromentLight(vehicle, light, offset, color)
    local boneIndex = GetEntityBoneIndexByName(vehicle, light)
    local coords = GetWorldPositionOfEntityBone(vehicle, boneIndex)
    local position = coords + offset

    local rgb = { 0, 0, 0 }
    local range = 50.0
    local intensity = 1.0
    local shadow = 1.0

    if string.lower(color) == 'blue' then rgb = { 0, 0, 255 }
    elseif string.lower(color) == 'red' then rgb = { 255, 0, 0 }
    elseif string.lower(color) == 'green' then rgb = { 0, 255, 0 }
    elseif string.lower(color) == 'white' then rgb = { 255, 255, 255 }
    elseif string.lower(color) == 'amber' then rgb = { 255, 194, 0}
    end

    -- draw the light
    DrawLightWithRangeAndShadow(
        position.x, position.y, position.z,
        rgb[1], rgb[2], rgb[3],
        range, intensity, shadow
    )
end