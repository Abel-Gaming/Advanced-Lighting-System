-- LIGHTS
PrimaryLightsActivated = false
SecondaryLightsActivated = false
WarningLightsActivated = false

-- SIRENS
PrimarySirenActivated = false
SecondarySirenActivated = false

-- Sounds are keyed by vehicle NETWORK ID (stable across clients), not by
-- the local entity handle.
activeSounds = {}

-- MISC
ALSLocked = false
ModuleOpen = true

----- PLAYER LOADED -----
Citizen.CreateThread(function()
	while not NetworkIsSessionStarted() do
		Wait(500)
	end

    sendChatMessageInfo('Loaded Advanced Lighting System by Abel Gaming')
    print('Loaded Advanced Lighting System by Abel Gaming')

    -- NOTE: the old script called DisableActiveExtras() with no vehicle
    -- argument here, which did nothing useful (and could error). Removed.

    RegisterKeyMapping('AG-ALS-FiveM-Primary', 'Toggle Primary Lights', 'KEYBOARD', 'Q')
    RegisterKeyMapping('AG-ALS-FiveM-Secondary', 'Toggle Secondary Lights', 'KEYBOARD', 'K')
    RegisterKeyMapping('AG-ALS-FiveM-Warning', 'Toggle Warning Lights', 'KEYBOARD', 'J')
    RegisterKeyMapping('AG-ALS-FiveM-Lock', 'Lock ALS', 'KEYBOARD', 'F24')
    RegisterKeyMapping('AG-ALS-FiveM-PrimarySiren', 'Toggle Primary Siren', 'KEYBOARD', 'LALT')
    -- Was also bound to LALT in the original script, which meant the two
    -- commands fought over the same key by default.
    RegisterKeyMapping('AG-ALS-FiveM-SecondarySiren', 'Toggle Secondary Siren', 'KEYBOARD', 'Y')

    if Config.UseWMServerSirens then
        RequestScriptAudioBank('DLC_WMSIRENS\\SIRENPACK_ONE', false)
    end

    Citizen.CreateThread(UpdateVehicles)
end)

----- AUTO-OFF IF THE PLAYER LEAVES THE VEHICLE -----
-- Entity handles get recycled by the game once an entity is deleted. If a
-- player exited the vehicle (or it despawned) while lights/sirens were on,
-- the old script kept flashing extras against that stale handle, which can
-- end up hitting a completely unrelated entity that reused the same number.
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(500)
        if PrimaryLightsActivated or SecondaryLightsActivated or WarningLightsActivated then
            local ped = PlayerPedId()
            if not IsPedInAnyVehicle(ped, false) then
                local veh = GetVehiclePedIsUsing(ped)
                DisableActiveExtras(veh)
                if PrimarySirenActivated then
                    TriggerServerEvent('ALS:StopPrimarySirenServer', GetVehicleNetId(veh))
                end
                if SecondarySirenActivated then
                    TriggerServerEvent('ALS:StopSecondarySirenServer', GetVehicleNetId(veh))
                end
                PrimaryLightsActivated = false
                SecondaryLightsActivated = false
                WarningLightsActivated = false
                PrimarySirenActivated = false
                SecondarySirenActivated = false
            end
        end
    end
end)

----- ENVIRONMENT LIGHTS -----
-- DrawLightWithRangeAndShadow is purely local to whoever calls it, so this
-- can't be driven by our own PrimaryLightsActivated/etc flags (those only
-- exist on the driver's client). Instead every client independently checks
-- each nearby configured vehicle's actual extra state - which IS synced by
-- the game. This thread just decides whether the effect should be running
-- at all for a vehicle (any of extras 1-9 on); the actual flash timing per
-- light is handled every frame inside CreateEnvironmentLight itself, based
-- on each light's own `Extras` list (see config.lua).

local vehicleConfigByHash = {}
for model, cfg in pairs(Config.Vehicles) do
    vehicleConfigByHash[GetHashKey(model)] = cfg
end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(300)

        -- Stop lights on vehicles that no longer qualify (extras off, or
        -- vehicle gone).
        for vehicle in pairs(ActiveEnvironmentLights) do
            if not IsShowingEmergencyLights(vehicle) then
                StopEnvironmentLight(vehicle)
            end
        end

        -- Start lights on any configured, streamed-in vehicle that now
        -- qualifies and isn't already running.
        for _, vehicle in ipairs(GetGamePool('CVehicle')) do
            if not ActiveEnvironmentLights[vehicle] then
                local cfg = vehicleConfigByHash[GetEntityModel(vehicle)]
                if cfg and IsShowingEmergencyLights(vehicle) then
                    StartEnvironmentLights(vehicle, cfg)
                end
            end
        end
    end
end)

----- DRAW PANEL -----
Citizen.CreateThread(function()
    while not NetworkIsSessionStarted() do
		Wait(500)
	end

    while true do
        Citizen.Wait(1)
        if IsControlModuleOpen() then
            if IsPedInAnyVehicle(GetPlayerPed(-1)) then
                local playerped = GetPlayerPed(-1)
                local veh = GetVehiclePedIsUsing(playerped)
                if GetVehicleClass(veh) == 18 then
                    local panelOffsetX = 0.0
                    local panelOffsetY = 0.0
                    _DrawRect(0.85 + panelOffsetX, 0.89 + panelOffsetY, 0.26, 0.16, 16, 16, 16, 225, 0)
                    _DrawRect(0.85 + panelOffsetX, 0.835 + panelOffsetY, 0.245, 0.035, 0, 0, 0, 225, 0)
                    _DrawRect(0.85 + panelOffsetX, 0.835 + panelOffsetY, 0.24, 0.03, 186, 186, 186, 225, 0)
                    Draw("MAIN", 0, 0, 0, 255, 0.745 + panelOffsetX, 0.825 + panelOffsetY, 0.25, 0.25, 1, true, 0)
                    Draw("Advanced Lighting System", 0, 0, 0, 255, 0.92 + panelOffsetX, 0.825 + panelOffsetY, 0.25, 0.25, 1, true, 0)
                    _DrawRect(0.78 + panelOffsetX, 0.835 + panelOffsetY, 0.033, 0.025, 0, 0, 0, 225, 0)

                    -- Light Stage One
                    if AreWarningLightsActivated() then
                        _DrawRect(0.815 + panelOffsetX, 0.835 + panelOffsetY, 0.033, 0.025, 0, 0, 0, 225, 0)
                        _DrawRect(0.78 + panelOffsetX, 0.835 + panelOffsetY, 0.03, 0.02, 199, 152, 0, 225, 0)
                        Draw("S-1", 0, 0, 0, 255, 0.78 + panelOffsetX, 0.825 + panelOffsetY, 0.25, 0.25, 1, true, 0)
                    else
                        _DrawRect(0.815 + panelOffsetX, 0.835 + panelOffsetY, 0.033, 0.025, 0, 0, 0, 225, 0)
                        _DrawRect(0.78 + panelOffsetX, 0.835 + panelOffsetY, 0.03, 0.02, 186, 186, 186, 225, 0)
                        Draw("S-1", 0, 0, 0, 255, 0.78 + panelOffsetX, 0.825 + panelOffsetY, 0.25, 0.25, 1, true, 0)
                    end

                    -- Light Stage Two
                    if AreSecondaryLightsActivated() then
                        _DrawRect(0.815 + panelOffsetX, 0.835 + panelOffsetY, 0.03, 0.02, 199, 152, 0, 225, 0)
                        Draw("S-2", 0, 0, 0, 255, 0.815 + panelOffsetX, 0.825 + panelOffsetY, 0.25, 0.25, 1, true, 0)
                    else
                        _DrawRect(0.815 + panelOffsetX, 0.835 + panelOffsetY, 0.03, 0.02, 186, 186, 186, 225, 0)
                        Draw("S-2", 0, 0, 0, 255, 0.815 + panelOffsetX, 0.825 + panelOffsetY, 0.25, 0.25, 1, true, 0)
                    end

                    -- Light Stage Three [PRIMARY]
                    _DrawRect(0.850 + panelOffsetX, 0.835 + panelOffsetY, 0.033, 0.025, 0, 0, 0, 225, 0)
                    if ArePrimaryLightsActivated() then
                        _DrawRect(0.850 + panelOffsetX, 0.835 + panelOffsetY, 0.03, 0.02, 199, 152, 0, 225, 0)
                        Draw("S-3", 0, 0, 0, 255, 0.850 + panelOffsetX, 0.825 + panelOffsetY, 0.25, 0.25, 1, true, 0)
                    else
                        _DrawRect(0.850 + panelOffsetX, 0.835 + panelOffsetY, 0.03, 0.02, 186, 186, 186, 225, 0)
                        Draw("S-3", 0, 0, 0, 255, 0.850 + panelOffsetX, 0.825 + panelOffsetY, 0.25, 0.25, 1, true, 0)
                    end

                    -- Warning Lights
                    _DrawRect(0.742 + panelOffsetX, 0.88 + panelOffsetY, 0.028, 0.045, 0, 0, 0, 225, 0)
                    if AreWarningLightsActivated() then
                        _DrawRect(0.7421 + panelOffsetX, 0.871 + panelOffsetY, 0.026, 0.02, 199, 152, 0, 225, 0)
                        Draw("E - 00", 199, 152, 0, 255, 0.7423 + panelOffsetX, 0.88 + panelOffsetY, 0.25, 0.25, 1, true, 0)
                    else
                        _DrawRect(0.7421 + panelOffsetX, 0.871 + panelOffsetY, 0.026, 0.02, 186, 186, 186, 225, 0)
                        Draw("E - 00", 255, 255, 255, 255, 0.7423 + panelOffsetX, 0.88 + panelOffsetY, 0.25, 0.25, 1, true, 0)
                    end
                    Draw("WRN", 0, 0, 0, 255, 0.7423 + panelOffsetX, 0.86 + panelOffsetY, 0.25, 0.25, 1, true, 0)

                    -- Secondary Lights
                    _DrawRect(0.774 + panelOffsetX, 0.88 + panelOffsetY, 0.028, 0.045, 0, 0, 0, 225, 0)
                    if AreSecondaryLightsActivated() then
                        _DrawRect(0.774 + panelOffsetX, 0.871 + panelOffsetY, 0.025, 0.02, 199, 152, 0, 225, 0)
                        Draw("E - 00", 199, 152, 0, 255, 0.774 + panelOffsetX, 0.88 + panelOffsetY, 0.25, 0.25, 1, true, 0)
                    else
                        _DrawRect(0.774 + panelOffsetX, 0.871 + panelOffsetY, 0.025, 0.02, 186, 186, 186, 225, 0)
                        Draw("E - 00", 255, 255, 255, 255, 0.774 + panelOffsetX, 0.88 + panelOffsetY, 0.25, 0.25, 1, true, 0)
                    end
                    Draw("SEC", 0, 0, 0, 255, 0.774 + panelOffsetX, 0.86 + panelOffsetY, 0.25, 0.25, 1, true, 0)

                    -- Primary Lights
                    _DrawRect(0.806 + panelOffsetX, 0.88 + panelOffsetY, 0.028, 0.045, 0, 0, 0, 225, 0)
                    if ArePrimaryLightsActivated() then
                        _DrawRect(0.806 + panelOffsetX, 0.871 + panelOffsetY, 0.025, 0.02, 199, 152, 0, 225, 0)
                        Draw("E - 00", 199, 152, 0, 255, 0.806 + panelOffsetX, 0.88 + panelOffsetY, 0.25, 0.25, 1, true, 0)
                    else
                        _DrawRect(0.806 + panelOffsetX, 0.871 + panelOffsetY, 0.025, 0.02, 186, 186, 186, 225, 0)
                        Draw("E - 00", 255, 255, 255, 255, 0.806 + panelOffsetX, 0.88 + panelOffsetY, 0.25, 0.25, 1, true, 0)
                    end
                    Draw("PRIM", 0, 0, 0, 255, 0.806 + panelOffsetX, 0.86 + panelOffsetY, 0.25, 0.25, 1, true, 0)

                    -- HeadLights
                    _DrawRect(0.838 + panelOffsetX, 0.88 + panelOffsetY, 0.028, 0.045, 0, 0, 0, 225, 0)
                    if GetHeadlightStatus(veh) then
                        _DrawRect(0.838 + panelOffsetX, 0.871 + panelOffsetY, 0.025, 0.02, 199, 152, 0, 225, 0)
                        Draw("--", 199, 152, 0, 255, 0.838 + panelOffsetX, 0.88 + panelOffsetY, 0.25, 0.25, 1, true, 0)
                    else
                        _DrawRect(0.838 + panelOffsetX, 0.871 + panelOffsetY, 0.025, 0.02, 186, 186, 186, 225, 0)
                        Draw("--", 255, 255, 255, 255, 0.838 + panelOffsetX, 0.88 + panelOffsetY, 0.25, 0.25, 1, true, 0)
                    end
                    Draw("HL", 0, 0, 0, 255, 0.838 + panelOffsetX, 0.86 + panelOffsetY, 0.25, 0.25, 1, true, 0)

                    -- ALS Lock
                    _DrawRect(0.870 + panelOffsetX, 0.88 + panelOffsetY, 0.028, 0.045, 0, 0, 0, 225, 0)
                    if ALSLocked then
                        _DrawRect(0.870 + panelOffsetX, 0.871 + panelOffsetY, 0.025, 0.02, 219, 40, 40, 225, 0)
                        Draw("--", 219, 40, 40, 255, 0.870 + panelOffsetX, 0.88 + panelOffsetY, 0.25, 0.25, 1, true, 0)
                    else
                        _DrawRect(0.870 + panelOffsetX, 0.871 + panelOffsetY, 0.025, 0.02, 186, 186, 186, 225, 0)
                        Draw("--", 255, 255, 255, 255, 0.870 + panelOffsetX, 0.88 + panelOffsetY, 0.25, 0.25, 1, true, 0)
                    end
                    Draw("LOCK", 0, 0, 0, 255, 0.870 + panelOffsetX, 0.86 + panelOffsetY, 0.25, 0.25, 1, true, 0)

                    -- PRIMARY SIREN
                    _DrawRect(0.742 + panelOffsetX, 0.93 + panelOffsetY, 0.028, 0.045, 0, 0, 0, 225, 0)
                    Draw("--", 255, 255, 255, 255, 0.7423 + panelOffsetX, 0.93 + panelOffsetY, 0.25, 0.25, 1, true, 0)
                    Draw("PRIM", 0, 0, 0, 255, 0.7423 + panelOffsetX, 0.91 + panelOffsetY, 0.25, 0.25, 1, true, 0)
                    if PrimarySirenActivated then
                        _DrawRect(0.7421 + panelOffsetX, 0.921 + panelOffsetY, 0.026, 0.02, 199, 152, 0, 225, 0)
                    else
                        _DrawRect(0.7421 + panelOffsetX, 0.921 + panelOffsetY, 0.026, 0.02, 186, 186, 186, 225, 0)
                    end

                    -- SECONDARY SIREN
                    _DrawRect(0.774 + panelOffsetX, 0.93 + panelOffsetY, 0.028, 0.045, 0, 0, 0, 225, 0)
                    Draw("--", 255, 255, 255, 255, 0.774 + panelOffsetX, 0.93 + panelOffsetY, 0.25, 0.25, 1, true, 0)
                    Draw("SEC", 0, 0, 0, 255, 0.774 + panelOffsetX, 0.91 + panelOffsetY, 0.25, 0.25, 1, true, 0)
                    if SecondarySirenActivated then
                        _DrawRect(0.774 + panelOffsetX, 0.921 + panelOffsetY, 0.026, 0.02, 199, 152, 0, 225, 0)
                    else
                        _DrawRect(0.774 + panelOffsetX, 0.921 + panelOffsetY, 0.026, 0.02, 186, 186, 186, 225, 0)
                    end
                end
            end
        end
    end
end)