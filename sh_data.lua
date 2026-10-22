-- Shared helpers for the in-game editor.
-- Converts between Config.Vehicles / Config.Patterns and a plain,
-- JSON-safe table, validates anything that comes from a client, and
-- writes a config.lua-style export.
--
-- Plain data format:
-- {
--   vehicles = { { model = "police", pattern = 1,
--                  lights = { { bone = "extra_1", offset = {0,0,0}, color = "red", extras = {1,2} } } } },
--   patterns = { { id = 1, flashDelay = 250, Primary = { {1,2}, {3,4} }, Secondary = {...}, Warning = {...} } }
-- }

ALSData = {}
ALSData.Stages = { 'Primary', 'Secondary', 'Warning' }
ALSData.Colors = { red = true, blue = true, green = true, amber = true, white = true }

local MAX_VEHICLES, MAX_PATTERNS, MAX_LIGHTS, MAX_STEPS = 500, 200, 32, 64

local function trim(s)
    return (s:gsub('^%s+', ''):gsub('%s+$', ''))
end

local function clampNum(v, def, min, max)
    v = tonumber(v)
    if not v or v ~= v then v = def end
    if v < min then v = min elseif v > max then v = max end
    return v
end

local function cleanExtras(t)
    local out, seen = {}, {}
    if type(t) == 'table' then
        for _, e in ipairs(t) do
            e = tonumber(e)
            if e then
                e = math.floor(e)
                if e >= 0 and e <= 20 and not seen[e] then
                    seen[e] = true
                    out[#out + 1] = e
                end
            end
        end
    end
    table.sort(out)
    return out
end

-- Returns a cleaned copy, or nil + error message
function ALSData.Sanitize(d)
    if type(d) ~= 'table' then return nil, 'Invalid data.' end
    local out = { vehicles = {}, patterns = {} }

    local patIds, firstId = {}, nil
    if type(d.patterns) == 'table' then
        for _, p in ipairs(d.patterns) do
            if #out.patterns >= MAX_PATTERNS then break end
            if type(p) == 'table' then
                local id = math.floor(tonumber(p.id) or 0)
                if id >= 1 and id <= 9999 and not patIds[id] then
                    patIds[id] = true
                    firstId = firstId or id
                    local np = { id = id, flashDelay = math.floor(clampNum(p.flashDelay, 250, 30, 5000)) }
                    for _, stage in ipairs(ALSData.Stages) do
                        np[stage] = {}
                        if type(p[stage]) == 'table' then
                            for _, step in ipairs(p[stage]) do
                                if #np[stage] >= MAX_STEPS then break end
                                np[stage][#np[stage] + 1] = cleanExtras(step)
                            end
                        end
                    end
                    out.patterns[#out.patterns + 1] = np
                end
            end
        end
    end
    if #out.patterns == 0 then return nil, 'You need at least one pattern.' end
    table.sort(out.patterns, function(a, b) return a.id < b.id end)

    local models = {}
    if type(d.vehicles) == 'table' then
        for _, v in ipairs(d.vehicles) do
            if #out.vehicles >= MAX_VEHICLES then break end
            if type(v) == 'table' and type(v.model) == 'string' then
                local model = trim(v.model)
                if model == '' or #model > 64 or not model:match('^[%w_%-]+$') then
                    return nil, ('Invalid vehicle model name "%s". Use letters, numbers, - and _ only.'):format(model)
                end
                if models[model:lower()] then
                    return nil, ('Vehicle "%s" is listed twice.'):format(model)
                end
                models[model:lower()] = true

                local pattern = math.floor(tonumber(v.pattern) or firstId)
                if not patIds[pattern] then pattern = firstId end

                local lights = {}
                if type(v.lights) == 'table' then
                    for _, l in ipairs(v.lights) do
                        if #lights >= MAX_LIGHTS then break end
                        if type(l) == 'table' then
                            local bone = type(l.bone) == 'string' and trim(l.bone) or ''
                            if bone ~= '' and #bone <= 64 and bone:match('^[%w_%.%-]+$') then
                                local o = type(l.offset) == 'table' and l.offset or {}
                                local color = type(l.color) == 'string' and l.color:lower() or 'white'
                                if not ALSData.Colors[color] then color = 'white' end
                                lights[#lights + 1] = {
                                    bone = bone,
                                    offset = {
                                        clampNum(o[1], 0.0, -10.0, 10.0) + 0.0,
                                        clampNum(o[2], 0.0, -10.0, 10.0) + 0.0,
                                        clampNum(o[3], 0.0, -10.0, 10.0) + 0.0,
                                    },
                                    color = color,
                                    extras = cleanExtras(l.extras),
                                }
                            end
                        end
                    end
                end

                out.vehicles[#out.vehicles + 1] = { model = model, pattern = pattern, lights = lights }
            end
        end
    end
    table.sort(out.vehicles, function(a, b) return a.model:lower() < b.model:lower() end)

    return out
end

-- Config tables -> plain data
function ALSData.FromConfig()
    local d = { vehicles = {}, patterns = {} }

    for id, p in pairs(Config.Patterns or {}) do
        local np = { id = tonumber(id), flashDelay = p.FlashDelay or 250 }
        for _, stage in ipairs(ALSData.Stages) do
            np[stage] = {}
            for _, step in ipairs(p[stage] or {}) do
                np[stage][#np[stage] + 1] = cleanExtras(step.Extras)
            end
        end
        d.patterns[#d.patterns + 1] = np
    end

    for model, cfg in pairs(Config.Vehicles or {}) do
        local lights = {}
        for _, l in ipairs(cfg.EnvironmentLights or {}) do
            local o = l.Offset or vector3(0.0, 0.0, 0.0)
            lights[#lights + 1] = {
                bone = l.Bone,
                offset = { o.x, o.y, o.z },
                color = string.lower(l.Color or 'white'),
                extras = cleanExtras(l.Extras),
            }
        end
        d.vehicles[#d.vehicles + 1] = { model = model, pattern = cfg.Pattern or 1, lights = lights }
    end

    return ALSData.Sanitize(d) or d
end

-- Plain data -> Config tables (replaces them)
function ALSData.ToConfig(d)
    local patterns = {}
    for _, p in ipairs(d.patterns) do
        local np = { FlashDelay = p.flashDelay }
        for _, stage in ipairs(ALSData.Stages) do
            np[stage] = {}
            for _, step in ipairs(p[stage] or {}) do
                np[stage][#np[stage] + 1] = { Extras = step }
            end
        end
        patterns[p.id] = np
    end

    local vehicles = {}
    for _, v in ipairs(d.vehicles) do
        local lights = {}
        for _, l in ipairs(v.lights or {}) do
            lights[#lights + 1] = {
                Bone = l.bone,
                Offset = vector3(l.offset[1] + 0.0, l.offset[2] + 0.0, l.offset[3] + 0.0),
                Color = l.color,
                Extras = l.extras,
            }
        end
        vehicles[v.model] = { Pattern = v.pattern, EnvironmentLights = lights }
    end

    Config.Patterns = patterns
    Config.Vehicles = vehicles
end

-- Plain data -> text you can paste into config.lua
local function list(t)
    local s = {}
    for i, v in ipairs(t) do s[i] = tostring(v) end
    return '{' .. table.concat(s, ',') .. '}'
end

function ALSData.ToLua(d)
    local lines = {
        '-- Generated by the ALS in-game editor. Paste over Config.Vehicles / Config.Patterns in config.lua.',
        '',
        'Config.Vehicles = {',
    }
    for _, v in ipairs(d.vehicles) do
        lines[#lines + 1] = ('    [%q] = {'):format(v.model)
        lines[#lines + 1] = ('        Pattern = %d,'):format(v.pattern)
        lines[#lines + 1] = '        EnvironmentLights = {'
        for _, l in ipairs(v.lights) do
            lines[#lines + 1] = ('            { Bone = %q, Offset = vector3(%.3f, %.3f, %.3f), Color = %q, Extras = %s },')
                :format(l.bone, l.offset[1], l.offset[2], l.offset[3], l.color, list(l.extras))
        end
        lines[#lines + 1] = '        }'
        lines[#lines + 1] = '    },'
    end
    lines[#lines + 1] = '}'
    lines[#lines + 1] = ''
    lines[#lines + 1] = 'Config.Patterns = {'
    for _, p in ipairs(d.patterns) do
        lines[#lines + 1] = ('    [%d] = {'):format(p.id)
        for _, stage in ipairs(ALSData.Stages) do
            lines[#lines + 1] = ('        %s = {'):format(stage)
            for _, step in ipairs(p[stage]) do
                lines[#lines + 1] = ('            {Extras = %s},'):format(list(step))
            end
            lines[#lines + 1] = '        },'
        end
        lines[#lines + 1] = ('        FlashDelay = %d'):format(p.flashDelay)
        lines[#lines + 1] = '    },'
    end
    lines[#lines + 1] = '}'
    return table.concat(lines, '\n') .. '\n'
end
