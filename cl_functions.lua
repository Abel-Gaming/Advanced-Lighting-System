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

---------------------------------------------------------------------------
-- VEHICLE CONFIG LOOKUP (hash -> config, built once)
---------------------------------------------------------------------------
VehicleConfigByHash = {}
for model, cfg in pairs(Config.Vehicles) do
    VehicleConfigByHash[GetHashKey(model)] = cfg
end

function GetVehicleConfig(vehicle)
    return VehicleConfigByHash[GetEntityModel(vehicle)]
end

---------------------------------------------------------------------------
-- LIGHT ENGINE
--
-- Every vehicle with an active stage is tracked here in plain Lua tables.
-- ONE thread drives every vehicle (instead of one thread per stage per
-- vehicle + one thread per environment light), and the flash step is worked
-- out from the shared network clock, so every client is on the same flash
-- at the same moment. That keeps remote clients in phase with the driver,
-- which is what stops extras "fighting" the network sync and looking laggy.
---------------------------------------------------------------------------
local STAGES = { 'Warning', 'Secondary', 'Primary' }
ALS_COLORS = {
    red   = { 255, 0, 0 },
    blue  = { 0, 0, 255 },
    green = { 0, 255, 0 },
    amber = { 255, 194, 0 },
    white = { 255, 255, 255 },
}

ALSVehicles = {}   -- [vehicle] = { stages = {Primary=pid,...}, applied = {[extra]=true}, ... }
ALSSirens   = {}   -- [vehicle] = tone (mirrors the elsSiren state bag)
activeSounds = {}  -- [vehicle] = soundId

local patternExtrasCache = {}
local function getPatternExtras(patternId)
    local cached = patternExtrasCache[patternId]
    if cached then return cached end
    local set = {}
    local pattern = Config.Patterns[patternId]
    if pattern then
        for _, stageName in ipairs(STAGES) do
            for _, step in ipairs(pattern[stageName] or {}) do
                for _, e in ipairs(step.Extras or {}) do set[e] = true end
            end
        end
    end
    patternExtrasCache[patternId] = set
    return set
end

local function sharedClock()
    local t = GetNetworkTime()
    if not t or t == 0 then t = GetGameTimer() end
    return t
end

local function prepareVehicle(vehicle)
    local cfg = GetVehicleConfig(vehicle)
    local t = {
        stages = {},
        applied = {},
        hasExtra = {},
        lights = {},
    }

    SetVehicleAutoRepairDisabled(vehicle, true)

    -- Cache which extras exist so we never poll DoesExtraExist per frame
    for e = 0, 20 do
        if DoesExtraExist(vehicle, e) then t.hasExtra[e] = true end
    end

    t.lights = BuildEnvironmentLights(vehicle, cfg)

    ALSVehicles[vehicle] = t
    return t
end

-- Resolves a vehicle config's environment lights to cached bone indexes
function BuildEnvironmentLights(vehicle, cfg)
    local lights = {}
    if cfg and cfg.EnvironmentLights then
        for _, def in ipairs(cfg.EnvironmentLights) do
            local bone = GetEntityBoneIndexByName(vehicle, def.Bone)
            if bone == -1 then
                if Config.EnableDebugging then
                    print(("[ALS] Bone '%s' not found on vehicle model - environment light skipped."):format(def.Bone))
                end
            else
                local off = def.Offset or vector3(0.0, 0.0, 0.0)
                lights[#lights + 1] = {
                    bone = bone,
                    offset = off,
                    hasOffset = (off.x ~= 0.0 or off.y ~= 0.0 or off.z ~= 0.0),
                    rgb = ALS_COLORS[string.lower(def.Color or 'white')] or ALS_COLORS.white,
                    extras = def.Extras or {},
                }
            end
        end
    end
    return lights
end

-- Called after the vehicle/pattern setup changes (editor preview or a save
-- from the server). Rebuilds lookups and re-reads lights on lit vehicles.
function ALS_OnConfigChanged()
    for k in pairs(VehicleConfigByHash) do VehicleConfigByHash[k] = nil end
    for model, cfg in pairs(Config.Vehicles) do
        VehicleConfigByHash[GetHashKey(model)] = cfg
    end
    for k in pairs(patternExtrasCache) do patternExtrasCache[k] = nil end
    for vehicle, t in pairs(ALSVehicles) do
        if DoesEntityExist(vehicle) then
            t.lights = BuildEnvironmentLights(vehicle, GetVehicleConfig(vehicle))
        end
    end
end

local function setExtra(vehicle, t, extra, on)
    if not t.hasExtra[extra] then return end
    SetVehicleExtra(vehicle, extra, on and 0 or 1)
    t.applied[extra] = on or nil
end

local function shutdownVehicle(vehicle, t)
    if DoesEntityExist(vehicle) then
        for e in pairs(t.applied) do
            SetVehicleExtra(vehicle, e, 1)
        end
        if not ALSSirens[vehicle] then
            SetVehicleSiren(vehicle, false)
        end
    end
    ALSVehicles[vehicle] = nil
end

-- Called from the state bag handlers / sync scan.
function SetVehicleStage(vehicle, stageName, patternId)
    local t = ALSVehicles[vehicle]
    if patternId then
        if not t then t = prepareVehicle(vehicle) end
        if t.stages[stageName] ~= patternId then
            t.stages[stageName] = patternId
            -- Make sure every extra this pattern drives starts from "off"
            for e in pairs(getPatternExtras(patternId)) do
                if not t.applied[e] and t.hasExtra[e] then SetVehicleExtra(vehicle, e, 1) end
            end
        end
    elseif t then
        t.stages[stageName] = nil
        if next(t.stages) == nil and not (ALSStepPreview and ALSStepPreview.vehicle == vehicle) then
            shutdownVehicle(vehicle, t)
        end
    end
end

function IsVehicleStageActive(vehicle, stageName)
    local t = vehicle and ALSVehicles[vehicle]
    return t ~= nil and t.stages[stageName] ~= nil
end

-- Kept for compatibility with anything else that calls it
function IsShowingEmergencyLights(vehicle)
    local t = ALSVehicles[vehicle]
    return t ~= nil and next(t.applied) ~= nil
end

---------------------------------------------------------------------------
-- STEP PREVIEW (editor): hold one pattern step steady on a vehicle
---------------------------------------------------------------------------
ALSStepPreview = nil -- { vehicle = veh, extras = { [extra] = true } }

local function allPatternExtras()
    local set = {}
    for id in pairs(Config.Patterns) do
        for e in pairs(getPatternExtras(id)) do set[e] = true end
    end
    return set
end

-- extrasList = list of extra ids to show, or nil to stop previewing
function SetStepPreview(vehicle, extrasList)
    if vehicle and vehicle ~= 0 and extrasList and DoesEntityExist(vehicle) then
        local t = ALSVehicles[vehicle] or prepareVehicle(vehicle)
        local set = {}
        for _, e in ipairs(extrasList) do
            e = tonumber(e)
            if e then set[math.floor(e)] = true end
        end
        -- Start from a clean slate: every extra any pattern uses goes off
        -- unless it's in this step (cosmetic extras are left alone)
        for e in pairs(allPatternExtras()) do
            if not set[e] and t.hasExtra[e] then
                SetVehicleExtra(vehicle, e, 1)
                t.applied[e] = nil
            end
        end
        ALSStepPreview = { vehicle = vehicle, extras = set }
    else
        local p = ALSStepPreview
        ALSStepPreview = nil
        if p then
            local t = ALSVehicles[p.vehicle]
            if t and next(t.stages) == nil then shutdownVehicle(p.vehicle, t) end
        end
    end
end

local function computeDesired(t, now)
    local desired = {}
    for _, stageName in ipairs(STAGES) do
        local pid = t.stages[stageName]
        local pattern = pid and Config.Patterns[pid]
        local steps = pattern and pattern[stageName]
        if steps and #steps > 0 then
            local delay = pattern.FlashDelay or 250
            local idx = math.floor(now / delay) % #steps + 1
            for _, e in ipairs(steps[idx].Extras) do desired[e] = true end
        end
    end
    return desired
end

-- The single render/flash loop
Citizen.CreateThread(function()
    local patternDist = (Config.PatternDistance or 250.0)
    local lightDist = (Config.EnvLightDrawDistance or 120.0)
    local range = Config.ELSRange or 50.0
    local intensity = Config.ELSIntensity or 1.0

    while true do
        if next(ALSVehicles) == nil then
            Citizen.Wait(250)
        else
            Citizen.Wait(0)
            local now = sharedClock()
            local cam = GetFinalRenderedCamCoord()

            for vehicle, t in pairs(ALSVehicles) do
                if DoesEntityExist(vehicle) then
                    local vehPos = GetEntityCoords(vehicle)
                    local dist = #(vehPos - cam)

                    if dist <= patternDist then
                        -- Only touch extras that actually change this frame
                        local desired
                        if ALSStepPreview and ALSStepPreview.vehicle == vehicle then
                            desired = ALSStepPreview.extras
                        else
                            desired = computeDesired(t, now)
                        end
                        for e in pairs(t.applied) do
                            if not desired[e] then setExtra(vehicle, t, e, false) end
                        end
                        for e in pairs(desired) do
                            if not t.applied[e] then setExtra(vehicle, t, e, true) end
                        end

                        -- Environment lights (cached bones, no native polling)
                        if dist <= lightDist and #t.lights > 0 then
                            local right, forward, up
                            for _, l in ipairs(t.lights) do
                                local lit = false
                                for _, e in ipairs(l.extras) do
                                    if t.applied[e] then lit = true break end
                                end
                                if lit then
                                    local pos = GetWorldPositionOfEntityBone(vehicle, l.bone)
                                    if l.hasOffset then
                                        if not right then right, forward, up = GetEntityMatrix(vehicle) end
                                        local o = l.offset
                                        pos = pos + (right * o.x) + (forward * o.y) + (up * o.z)
                                    end
                                    DrawLightWithRangeAndShadow(pos.x, pos.y, pos.z, l.rgb[1], l.rgb[2], l.rgb[3], range, intensity, 0)
                                end
                            end
                        end
                    end
                else
                    ALSVehicles[vehicle] = nil
                    if ALSStepPreview and ALSStepPreview.vehicle == vehicle then ALSStepPreview = nil end
                end
            end
        end
    end
end)

---------------------------------------------------------------------------
-- SIRENS
---------------------------------------------------------------------------
local audioBankRequested = false

function StopVehicleSirenSound(vehicle)
    local id = activeSounds[vehicle]
    if id then
        StopSound(id)
        ReleaseSoundId(id)
        activeSounds[vehicle] = nil
    end
end

function ApplyVehicleSiren(vehicle, tone)
    StopVehicleSirenSound(vehicle)
    ALSSirens[vehicle] = tone

    if not tone then
        if not ALSVehicles[vehicle] and DoesEntityExist(vehicle) then
            SetVehicleSiren(vehicle, false)
        end
        return
    end

    local soundName = Config.SirenTones[tone]
    if not soundName or not DoesEntityExist(vehicle) then return end

    SetVehicleHasMutedSirens(vehicle, true)
    SetVehicleSiren(vehicle, true)

    local soundId = GetSoundId()
    activeSounds[vehicle] = soundId

    if Config.UseWMServerSirens then
        if not audioBankRequested then
            RequestScriptAudioBank(Config.WMServerSirensAudioBank, false)
            audioBankRequested = true
        end
        PlaySoundFromEntity(soundId, soundName, vehicle, Config.WMServerSirensSoundSet, 0, 0)
    else
        PlaySoundFromEntity(soundId, soundName, vehicle, 0, 0, 0)
    end
end

function GetVehicleSirenTone(vehicle)
    return vehicle and ALSSirens[vehicle] or nil
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

---------------------------------------------------------------------------
-- SYNC SCAN (once per second)
-- State bag handlers can fire before a vehicle has streamed in on this
-- client, so they'd be missed. This picks up any vehicle that arrives with
-- lights/siren already on, and cleans up vehicles that left.
---------------------------------------------------------------------------
Citizen.CreateThread(function()
    local bagKeys = { Primary = 'elsPrimary', Secondary = 'elsSecondary', Warning = 'elsWarning' }
    local myId = PlayerId()

    while true do
        Citizen.Wait(1000)

        -- cleanup
        for vehicle in pairs(ALSSirens) do
            if not DoesEntityExist(vehicle) then
                StopVehicleSirenSound(vehicle)
                ALSSirens[vehicle] = nil
            end
        end
        for vehicle in pairs(activeSounds) do
            if not DoesEntityExist(vehicle) then StopVehicleSirenSound(vehicle) end
        end

        -- pick up streamed-in vehicles
        for _, vehicle in ipairs(GetGamePool('CVehicle')) do
            if VehicleConfigByHash[GetEntityModel(vehicle)] or GetVehicleClass(vehicle) == 18 then
                if NetworkGetEntityIsNetworked(vehicle) then
                    local state = Entity(vehicle).state
                    local t = ALSVehicles[vehicle]
                    for stageName, key in pairs(bagKeys) do
                        local v = state[key]
                        local pid = v and v.patternId or nil
                        local current = t and t.stages[stageName] or nil
                        if pid ~= current then
                            SetVehicleStage(vehicle, stageName, pid)
                            t = ALSVehicles[vehicle]
                        end
                    end

                    local s = state.elsSiren
                    local tone = (s and s.active) and s.tone or nil
                    if tone ~= ALSSirens[vehicle] then
                        ApplyVehicleSiren(vehicle, tone)
                    end

                    -- keep the engine running on vehicles we own with lights on
                    if t and NetworkGetEntityOwner(vehicle) == myId and not GetIsVehicleEngineRunning(vehicle) then
                        SetVehicleEngineOn(vehicle, true, true, false)
                    end
                end
            end
        end
    end
end)

---------------------------------------------------------------------------
-- MISC HELPERS
---------------------------------------------------------------------------
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

----- UI DRAWING -----
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

-- Panel state now comes from the vehicle itself (state bags), so it's
-- correct per vehicle and matches what everyone else sees.
function ArePrimaryLightsActivated(vehicle)
	return IsVehicleStageActive(vehicle, 'Primary')
end

function AreSecondaryLightsActivated(vehicle)
	return IsVehicleStageActive(vehicle, 'Secondary')
end

function AreWarningLightsActivated(vehicle)
	return IsVehicleStageActive(vehicle, 'Warning')
end

function IsControlModuleOpen()
	return ModuleOpen
end

function IsSirenActive(vehicle)
	return GetVehicleSirenTone(vehicle) ~= nil
end

function UpdateVehicles()
    while true do
        TriggerEvent('ALS:GetPlayersAndVehicles')
        Citizen.Wait(Config.VehicleUpdateTime * 1000)
    end
end
