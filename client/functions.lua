function GetHeadlightStatus(vehicle)
    local retval, lightsOn, highbeamsOn = GetVehicleLightsState(vehicle)
    return lightsOn
end

function GetHeadlightHighBeamStatus(vehicle)
    local retval, lightsOn, highbeamsOn = GetVehicleLightsState(vehicle)
    return highbeamsOn
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

function toggleSirenMute(veh, toggle)
    if DoesEntityExist(veh) and not IsEntityDead(veh) then
        DisableVehicleImpactExplosionActivation(veh, toggle)
    end
end

function CreateEnvironmentLight(vehicle, light, offset, color)
    local boneIndex = GetEntityBoneIndexByName(vehicle, light)
    if boneIndex == -1 then
        print("Error: Bone '" .. light .. "' not found on vehicle.")
        return
    end

    local coords = GetWorldPositionOfEntityBone(vehicle, boneIndex)
    local position = coords + offset

    local rgb = { 255, 255, 255 } -- Default color: white
    local range = 50.0
    local intensity = 1.0
    local shadow = 1.0

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

    -- Draw the light
    DrawLightWithRangeAndShadow(
        position.x, position.y, position.z,
        rgb[1], rgb[2], rgb[3],
        range, intensity, shadow
    )
end

function EnablePrimaryStage(vehicle, vehicleConfig)
    while PrimaryLightsActivated do
        Citizen.Wait(1)
        SetVehicleEngineOn(vehicle, true, true, false)
        if Config.UseWMServerSirens then
            toggleSirenMute(vehicle, true)
            SetVehicleHasMutedSirens(vehicle, true)
            SetVehicleSiren(vehicle, true)
        end
        local lastFlash = {extras = {}}
        local pattern = Config.Patterns[vehicleConfig.Pattern]
        if pattern then
            for _, stage in ipairs(pattern.Primary) do
                for _, extraIndex in ipairs(stage.Extras) do
                    SetVehicleAutoRepairDisabled(vehicle, true)
                    ToggleExtra(vehicle, extraIndex, 0) --[[ If doens't really matter which one you enable here ]]
                    table.insert(lastFlash.extras, extraIndex)
                end
                Citizen.Wait(pattern.FlashDelay)
                for _, v in ipairs(lastFlash.extras) do
                    SetVehicleAutoRepairDisabled(vehicle, 1)
                    ToggleExtra(vehicle, v, false)
                end
                lastFlash.extras = {}
            end
        end
    end
end

function EnableSecondaryStage(vehicle, vehicleConfig)
    local ped = PlayerPedId()
    while SecondaryLightsActivated do
        Citizen.Wait(1)
        SetVehicleEngineOn(vehicle, true, true, false)
        local lastFlash = {extras = {}}
        local pattern = Config.Patterns[vehicleConfig.Pattern]
        if pattern then
            for _, stage in ipairs(pattern.Secondary) do
                for _, extraIndex in ipairs(stage.Extras) do
                    SetVehicleAutoRepairDisabled(vehicle, true)
                    ToggleExtra(vehicle, extraIndex, 0)
                    table.insert(lastFlash.extras, extraIndex)
                end
                Citizen.Wait(pattern.FlashDelay)
                for _, v in ipairs(lastFlash.extras) do
                    SetVehicleAutoRepairDisabled(vehicle, 1)
                    ToggleExtra(vehicle, v, false)
                end
                lastFlash.extras = {}
            end
        end
    end
end

function EnableWarningStage(vehicle, vehicleConfig)
    local ped = PlayerPedId()
    while WarningLightsActivated do
        Citizen.Wait(1)
        SetVehicleEngineOn(vehicle, true, true, false)
        local lastFlash = {extras = {}}
        local pattern = Config.Patterns[vehicleConfig.Pattern]
        if pattern then
            for _, stage in ipairs(pattern.Warning) do
                for _, extraIndex in ipairs(stage.Extras) do
                    SetVehicleAutoRepairDisabled(vehicle, true)
                    ToggleExtra(vehicle, extraIndex, 0)
                    table.insert(lastFlash.extras, extraIndex)
                end
                Citizen.Wait(pattern.FlashDelay)
                for _, v in ipairs(lastFlash.extras) do
                    SetVehicleAutoRepairDisabled(vehicle, 1)
                    ToggleExtra(vehicle, v, false)
                end
                lastFlash.extras = {}
            end
        end
    end
end

function DisableActiveExtras(vehicle)
	if vehicle ~= 0 then
        SetVehicleSiren(vehicle, false)
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

function ToggleExtra(vehicle, extra, toggle)
    local value = toggle and 0 or 1
    SetVehicleAutoRepairDisabled(vehicle, true)
    SetVehicleExtra(vehicle, extra, value)
end

function ToggleMisc(vehicle, misc, toggle)
    SetVehicleModKit(vehicle, 0)
    SetVehicleMod(vehicle, misc, toggle, false)
end

function isInTable(tbl, val)
    for _, v in ipairs(tbl) do
        if v == val then
            return true
        end
    end
    return false
end

function TogglePrimaryStage(vehicle, vehicleConfig, vehicleData)
    while vehicleData.PrimaryLights do
        Citizen.Wait(1) -- Wait to prevent crash

        -- Set the vehicle engine on
        SetVehicleEngineOn(vehicleData.entity, true, true, false) 

        local lastFlash = {extras = {}}
        local pattern = Config.Patterns[vehicleConfig.Pattern]
        if pattern then
            for _, stage in ipairs(pattern.Primary) do
                for _, extraIndex in ipairs(stage.Extras) do
                    SetVehicleAutoRepairDisabled(vehicleData.entity, true)
                    ToggleExtra(vehicleData.entity, extraIndex, 0) --[[ If doens't really matter which one you enable here ]]
                    table.insert(lastFlash.extras, extraIndex)
                end
                Citizen.Wait(pattern.FlashDelay)
                for _, v in ipairs(lastFlash.extras) do
                    SetVehicleAutoRepairDisabled(vehicleData.entity, 1)
                    ToggleExtra(vehicleData.entity, v, false)
                end
                lastFlash.extras = {}
            end
        end
    end
end