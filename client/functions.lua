RequestScriptAudioBank('DLC_WMSIRENS\\SIRENPACK_ONE', false)

function getClosestRoad(coords)
    local _, closestRoad, _, _ = GetClosestRoad(coords.x, coords.y, coords.z, 1, 1)
    return closestRoad
end

function GetHeadlightStatus(vehicle)
    local retval, lightsOn, highbeamsOn = GetVehicleLightsState(vehicle)
    return lightsOn
end

function GetHeadlightHighBeamStatus(vehicle)
    local retval, lightsOn, highbeamsOn = GetVehicleLightsState(vehicle)
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

function EnablePrimaryStage(vehicle, vehicleConfig)
    PrimaryLightsThread = GetIdOfThisThread()
    local ped = PlayerPedId()
    --local vehicle = GetVehiclePedIsUsing(ped)
    while ArePrimaryLightsActivated() do
        Citizen.Wait(1)
		SetVehicleAutoRepairDisabled(vehicle, true)
        SetVehicleSiren(vehicle, true)
        SetVehicleHasMutedSirens(vehicle, true)
		SetVehicleKeepEngineOnWhenAbandoned(vehicle, true)
        DisableVehicleImpactExplosionActivation(vehicle, true)
        local pattern = Config.Patterns[vehicleConfig.Pattern]
        if pattern then
            for _, stage in ipairs(pattern.Primary) do
                for _, extraIndex in ipairs(stage.Extras) do
                    SetVehicleExtra(vehicle, extraIndex, 0)
                end
                Citizen.Wait(pattern.FlashDelay)
                for _, extraIndex in ipairs(stage.Extras) do
                    SetVehicleExtra(vehicle, extraIndex, 1)
                end
            end
        end
    end
end

function EnableSecondaryStage(vehicle, vehicleConfig)
    local ped = PlayerPedId()
    --local vehicle = GetVehiclePedIsUsing(ped)
    while AreSecondaryLightsActivated() do
        Citizen.Wait(1)

		SetVehicleAutoRepairDisabled(vehicle, true)
		SetVehicleKeepEngineOnWhenAbandoned(vehicle, true)

        local pattern = Config.Patterns[vehicleConfig.Pattern]
        if pattern then
            for _, stage in ipairs(pattern.Secondary) do
                for _, extraIndex in ipairs(stage.Extras) do
                    SetVehicleExtra(vehicle, extraIndex, 0)
                end
                Citizen.Wait(pattern.FlashDelay)
                for _, extraIndex in ipairs(stage.Extras) do
                    SetVehicleExtra(vehicle, extraIndex, 1)
                end
            end
        end
    end
end

function EnableWarningStage(vehicle, vehicleConfig)
    local ped = PlayerPedId()
    --local vehicle = GetVehiclePedIsUsing(ped)
    while AreWarningLightsActivated() do
        Citizen.Wait(1)

		SetVehicleAutoRepairDisabled(vehicle, true)
		SetVehicleKeepEngineOnWhenAbandoned(vehicle, true)

        local pattern = Config.Patterns[vehicleConfig.Pattern]
        if pattern then
            for _, stage in ipairs(pattern.Warning) do
                for _, extraIndex in ipairs(stage.Extras) do
                    SetVehicleExtra(vehicle, extraIndex, 0)
                end
                Citizen.Wait(pattern.FlashDelay)
                for _, extraIndex in ipairs(stage.Extras) do
                    SetVehicleExtra(vehicle, extraIndex, 1)
                end
            end
        end
    end
end

function DisableLights(vehicle)
	if not ArePrimaryLightsActivated() then
		local ped = PlayerPedId()
		local vehicle = GetVehiclePedIsUsing(ped)
		if vehicle ~= 0 then
			SetVehicleExtra(vehicle, 1, 1)
			SetVehicleExtra(vehicle, 2, 1)
			SetVehicleExtra(vehicle, 3, 1)
			SetVehicleExtra(vehicle, 4, 1)
			SetVehicleExtra(vehicle, 5, 1)
			SetVehicleExtra(vehicle, 6, 1)
			SetVehicleExtra(vehicle, 7, 1)
			SetVehicleExtra(vehicle, 8, 1)
			SetVehicleExtra(vehicle, 9, 1)
			SetVehicleExtra(vehicle, 10, 1)
		end
	end
end

function DisableActiveExtras()
    local ped = PlayerPedId()
	local vehicle = GetVehiclePedIsUsing(ped)
	if vehicle ~= 0 then
		for ExtraID = 0, 20 do
            if DoesExtraExist(vehicle, ExtraID) then
                SetVehicleExtra(vehicle, ExtraID, 1)
            end
        end
	end
end

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