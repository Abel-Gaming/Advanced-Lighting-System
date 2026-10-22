-- ALS server: holds the live vehicle/pattern setup, saves edits from the
-- in-game editor and sends them to every client.
--
-- Saved edits live in data/als_data.json and override config.lua.
-- Delete that file (or run "als_reset" in the server console) to go back
-- to config.lua.

local RES = GetCurrentResourceName()
local DATA_FILE = Config.EditorDataFile or 'data/als_data.json'
local EXPORT_FILE = 'data/als_config_export.lua'

local CurrentData = nil
local lastSave = {}

local function loadData()
    local raw = LoadResourceFile(RES, DATA_FILE)
    if raw and raw ~= '' then
        local ok, decoded = pcall(json.decode, raw)
        if ok and decoded then
            local clean, err = ALSData.Sanitize(decoded)
            if clean then
                CurrentData = clean
                ALSData.ToConfig(clean)
                print(('[ALS] Loaded %d vehicle setups from %s'):format(#clean.vehicles, DATA_FILE))
                return
            end
            print(('[ALS] %s is invalid (%s). Using config.lua instead.'):format(DATA_FILE, err or '?'))
        else
            print(('[ALS] Could not read %s. Using config.lua instead.'):format(DATA_FILE))
        end
    end
    CurrentData = ALSData.FromConfig()
end

loadData()

local allowedPlayers = {}
for _, id in ipairs(Config.EditorAllowedPlayers or {}) do
    allowedPlayers[string.lower(id)] = true
end

local function canEdit(src)
    if not Config.EditorRequireAce then return true end
    if IsPlayerAceAllowed(src, Config.EditorAce or 'als.editor') then return true end
    for _, id in ipairs(GetPlayerIdentifiers(src)) do
        if allowedPlayers[string.lower(id)] then return true end
    end
    return false
end

RegisterNetEvent('ALS:requestData', function()
    TriggerLatentClientEvent('ALS:syncData', source, 50000, CurrentData)
end)

RegisterNetEvent('ALS:openEditor', function()
    local src = source
    if canEdit(src) then
        TriggerLatentClientEvent('ALS:editorAllowed', src, 50000, CurrentData)
    else
        TriggerClientEvent('ALS:editorDenied', src)
    end
end)

RegisterNetEvent('ALS:saveData', function(data)
    local src = source
    if not canEdit(src) then return end

    local now = GetGameTimer()
    if lastSave[src] and now - lastSave[src] < 1000 then
        TriggerClientEvent('ALS:saveResult', src, false, 'Slow down - wait a second before saving again.')
        return
    end
    lastSave[src] = now

    local clean, err = ALSData.Sanitize(data)
    if not clean then
        TriggerClientEvent('ALS:saveResult', src, false, err)
        return
    end

    if not SaveResourceFile(RES, DATA_FILE, json.encode(clean, { indent = true }), -1) then
        TriggerClientEvent('ALS:saveResult', src, false, 'Could not write ' .. DATA_FILE .. ' (check the data folder exists).')
        return
    end
    SaveResourceFile(RES, EXPORT_FILE, ALSData.ToLua(clean), -1)

    CurrentData = clean
    ALSData.ToConfig(clean)
    TriggerLatentClientEvent('ALS:syncData', -1, 50000, clean)
    TriggerClientEvent('ALS:saveResult', src, true,
        ('Saved %d vehicles and %d patterns.'):format(#clean.vehicles, #clean.patterns))
    print(('[ALS] %s saved vehicle setups (%d vehicles, %d patterns)'):format(
        GetPlayerName(src) or src, #clean.vehicles, #clean.patterns))
end)

AddEventHandler('playerDropped', function()
    lastSave[source] = nil
end)

-- Console: reload the saved file, or throw it away and use config.lua again
RegisterCommand('als_reload', function(src)
    if src ~= 0 then return end
    loadData()
    TriggerLatentClientEvent('ALS:syncData', -1, 50000, CurrentData)
end, true)

RegisterCommand('als_reset', function(src)
    if src ~= 0 then return end
    SaveResourceFile(RES, DATA_FILE, '', -1)
    print('[ALS] Cleared saved editor data. Restart ALS to load config.lua again.')
end, true)
