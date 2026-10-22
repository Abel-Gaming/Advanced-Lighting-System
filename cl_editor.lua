-- ALS in-game vehicle editor (client side).
-- /alseditor (default key F7) opens it. Changes preview live on your own
-- client; Save sends them to the server, which updates everyone.

local editorOpen = false
local editorFocused = false
local serverData = nil      -- last setup received from the server
local selected = nil        -- { model = "...", index = n } light highlighted in the editor

-- Bones worth offering in the editor's bone list (only ones that exist on your car are sent)
local CANDIDATE_BONES = {
    'bodyshell', 'chassis', 'chassis_dummy', 'windscreen', 'windscreen_r', 'bonnet', 'boot',
    'headlight_l', 'headlight_r', 'taillight_l', 'taillight_r', 'indicator_lf', 'indicator_rf',
    'indicator_lr', 'indicator_rr', 'brakelight_l', 'brakelight_r', 'brakelight_m',
    'reversinglight_l', 'reversinglight_r', 'neon_f', 'neon_b', 'neon_l', 'neon_r',
    'door_dside_f', 'door_pside_f', 'door_dside_r', 'door_pside_r', 'bumper_f', 'bumper_r',
}
for i = 1, 20 do CANDIDATE_BONES[#CANDIDATE_BONES + 1] = 'siren' .. i end
for i = 1, 14 do CANDIDATE_BONES[#CANDIDATE_BONES + 1] = 'extra_' .. i end

local function notify(msg)
    TriggerEvent('chat:addMessage', { color = { 199, 152, 0 }, args = { 'ALS', msg } })
end

local function deepCopy(t)
    if type(t) ~= 'table' then return t end
    local c = {}
    for k, v in pairs(t) do c[k] = deepCopy(v) end
    return c
end

local function applyLocal(data)
    ALSData.ToConfig(data)
    ALS_OnConfigChanged()
end

local function currentVehicleInfo()
    local veh = GetVehiclePedIsIn(PlayerPedId(), false)
    if veh == 0 then return nil end

    local model = GetEntityArchetypeName(veh)
    if not model or model == '' then
        model = string.lower(GetDisplayNameFromVehicleModel(GetEntityModel(veh)))
    end

    local extras = {}
    for e = 0, 20 do
        if DoesExtraExist(veh, e) then extras[#extras + 1] = e end
    end

    local bones = {}
    for _, b in ipairs(CANDIDATE_BONES) do
        if GetEntityBoneIndexByName(veh, b) ~= -1 then bones[#bones + 1] = b end
    end

    local state = Entity(veh).state
    local siren = state.elsSiren
    return {
        model = model,
        emergency = GetVehicleClass(veh) == 18,
        extras = extras,
        bones = bones,
        stages = {
            Primary = state.elsPrimary ~= nil,
            Secondary = state.elsSecondary ~= nil,
            Warning = state.elsWarning ~= nil,
        },
        siren = siren and siren.active and siren.tone or nil,
    }
end

----- SYNC FROM SERVER -----
RegisterNetEvent('ALS:syncData', function(data)
    serverData = data
    if editorOpen then
        -- Don't wipe out someone's unsaved preview; just let them know
        SendNUIMessage({ action = 'remoteSaved', data = data })
    else
        applyLocal(data)
    end
end)

CreateThread(function()
    while not NetworkIsSessionStarted() do Wait(500) end
    TriggerServerEvent('ALS:requestData')
end)

----- OPEN / CLOSE -----
local function setFocus(on)
    editorFocused = on
    SetNuiFocus(on, on)
    SendNUIMessage({ action = 'focus', focused = on })
end

RegisterCommand('alseditor', function()
    if editorOpen then
        -- Editor already open but mouse released: grab focus again
        if not editorFocused then setFocus(true) end
        return
    end
    TriggerServerEvent('ALS:openEditor')
end, false)

RegisterKeyMapping('alseditor', 'ALS: Open vehicle editor', 'keyboard', 'F7')

RegisterNetEvent('ALS:editorDenied', function()
    notify("You don't have permission to use the ALS editor.")
end)

RegisterNetEvent('ALS:editorAllowed', function(data)
    serverData = data
    editorOpen = true
    SendNUIMessage({ action = 'open', data = data, vehicle = currentVehicleInfo() })
    setFocus(true)
end)

local function closeEditor()
    SetStepPreview(nil)
    editorOpen = false
    selected = nil
    setFocus(false)
    SendNUIMessage({ action = 'close' })
    -- Throw away any unsaved preview
    if serverData then applyLocal(serverData) end
end

----- NUI CALLBACKS -----
RegisterNUICallback('close', function(_, cb)
    closeEditor()
    cb({})
end)

RegisterNUICallback('releaseFocus', function(_, cb)
    setFocus(false)
    notify('Mouse released. Press F7 (or /alseditor) to go back to the editor.')
    cb({})
end)

RegisterNUICallback('vehicleInfo', function(_, cb)
    cb(currentVehicleInfo() or { none = true })
end)

RegisterNUICallback('preview', function(body, cb)
    local clean, err = ALSData.Sanitize(body.data)
    if not clean then cb({ ok = false, error = err }) return end
    applyLocal(clean)

    -- If your car is lit and its pattern was changed, switch it over
    local veh = GetVehiclePedIsIn(PlayerPedId(), false)
    if veh ~= 0 then
        local cfg = GetVehicleConfig(veh)
        if cfg then
            local state = Entity(veh).state
            for _, key in ipairs({ 'elsPrimary', 'elsSecondary', 'elsWarning' }) do
                local v = state[key]
                if v and v.patternId ~= cfg.Pattern then
                    state:set(key, { patternId = cfg.Pattern }, true)
                end
            end
        end
    end
    cb({ ok = true })
end)

-- Hold one pattern step on your car while editing it ({ extras = {...} }, or {} to stop)
RegisterNUICallback('previewStep', function(body, cb)
    local veh = GetVehiclePedIsIn(PlayerPedId(), false)
    if veh ~= 0 and body and type(body.extras) == 'table' then
        SetStepPreview(veh, body.extras)
        cb({ ok = true })
    else
        SetStepPreview(nil)
        cb({ ok = veh ~= 0 })
    end
end)

RegisterNUICallback('selectLight', function(body, cb)
    if body and body.model and body.index then
        selected = { model = body.model, index = tonumber(body.index) }
    else
        selected = nil
    end
    cb({})
end)

local stageCommands = {
    Primary = 'AG-ALS-FiveM-Primary',
    Secondary = 'AG-ALS-FiveM-Secondary',
    Warning = 'AG-ALS-FiveM-Warning',
}

RegisterNUICallback('toggleStage', function(body, cb)
    local cmd = stageCommands[body and body.stage]
    SetStepPreview(nil)
    if cmd then ExecuteCommand(cmd) end
    Wait(150) -- let the state bag update before reporting back
    cb(currentVehicleInfo() or { none = true })
end)

RegisterNUICallback('save', function(body, cb)
    local clean, err = ALSData.Sanitize(body.data)
    if not clean then cb({ ok = false, error = err }) return end
    TriggerLatentServerEvent('ALS:saveData', 50000, clean)
    cb({ ok = true })
end)

RegisterNUICallback('exportLua', function(body, cb)
    local clean, err = ALSData.Sanitize(body.data)
    if not clean then cb({ ok = false, error = err }) return end
    cb({ ok = true, text = ALSData.ToLua(clean) })
end)

RegisterNetEvent('ALS:saveResult', function(ok, msg)
    SendNUIMessage({ action = 'saveResult', ok = ok, message = msg })
    if not editorOpen then notify(msg) end
end)

----- HIGHLIGHT THE SELECTED LIGHT ON YOUR CAR -----
CreateThread(function()
    while true do
        local veh = editorOpen and selected and GetVehiclePedIsIn(PlayerPedId(), false) or 0
        local cfg = veh ~= 0 and Config.Vehicles[selected.model] or nil

        if cfg and GetEntityModel(veh) == GetHashKey(selected.model) then
            Wait(0)
            local right, forward, up = GetEntityMatrix(veh)
            for i, l in ipairs(cfg.EnvironmentLights or {}) do
                local bone = GetEntityBoneIndexByName(veh, l.Bone)
                if bone ~= -1 then
                    local pos = GetWorldPositionOfEntityBone(veh, bone)
                    local o = l.Offset
                    if o then pos = pos + (right * o.x) + (forward * o.y) + (up * o.z) end
                    local c = ALS_COLORS[l.Color] or ALS_COLORS.white
                    local isSel = (i == selected.index)
                    local size = isSel and 0.16 or 0.07
                    DrawMarker(28, pos.x, pos.y, pos.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                        size, size, size, c[1], c[2], c[3], isSel and 210 or 120,
                        false, false, 2, false, nil, nil, false)
                    if isSel then
                        DrawLightWithRangeAndShadow(pos.x, pos.y, pos.z, c[1], c[2], c[3],
                            Config.ELSRange or 50.0, Config.ELSIntensity or 1.0, 0)
                    end
                end
            end
        else
            Wait(200)
        end
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() and editorOpen then
        SetNuiFocus(false, false)
    end
end)
