-- SIRENS / LIGHT STATE
-- Light stages and siren tone now live on the vehicle (entity state bags) and
-- are mirrored locally in ALSVehicles / ALSSirens (see cl_functions.lua).

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

    RegisterKeyMapping('AG-ALS-FiveM-Primary', 'Toggle Primary Lights', 'KEYBOARD', 'Q')
    RegisterKeyMapping('AG-ALS-FiveM-Secondary', 'Toggle Secondary Lights', 'KEYBOARD', 'K')
    RegisterKeyMapping('AG-ALS-FiveM-Warning', 'Toggle Warning Lights', 'KEYBOARD', 'J')
    RegisterKeyMapping('AG-ALS-FiveM-Lock', 'Lock ALS', 'KEYBOARD', 'F24')
    RegisterKeyMapping('AG-ALS-FiveM-Siren1', 'Wail Siren Tone', 'KEYBOARD', 'LALT')
    RegisterKeyMapping('AG-ALS-FiveM-Siren2', 'Yelp Siren Tone', 'KEYBOARD', 'Y')
    RegisterKeyMapping('AG-ALS-FiveM-Siren3', 'Priority Siren Tone', 'KEYBOARD', 'H')
    RegisterKeyMapping('AG-ALS-FiveM-Siren4', 'Hi-Lo Siren Tone', 'KEYBOARD', 'N')

    if Config.UseWMServerSirens then
        RequestScriptAudioBank(Config.WMServerSirensAudioBank, false)
    end

    Citizen.CreateThread(UpdateVehicles)
end)

----- AUTO-OFF IF THE PLAYER LEAVES THE VEHICLE -----
if Config.AutoOff then
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(500)
            local veh = LastALSVehicle
            if veh and DoesEntityExist(veh) then
                if GetVehiclePedIsIn(PlayerPedId(), false) ~= veh then
                    local state = Entity(veh).state
                    if state.elsPrimary then state:set('elsPrimary', nil, true) end
                    if state.elsSecondary then state:set('elsSecondary', nil, true) end
                    if state.elsWarning then state:set('elsWarning', nil, true) end
                    if state.elsSiren then ClearVehicleSirenState(veh) end
                    LastALSVehicle = nil
                end
            else
                LastALSVehicle = nil
            end
        end
    end)
end

----- DRAW PANEL -----
Citizen.CreateThread(function()
    while not NetworkIsSessionStarted() do
		Wait(500)
	end

    while true do
        local sleep = 500
        if IsControlModuleOpen() then
            local playerped = PlayerPedId()
            local veh = GetVehiclePedIsIn(playerped, false)
            if veh ~= 0 then
                if GetVehicleClass(veh) == 18 then
                    sleep = 0
                    local sirenTone = GetVehicleSirenTone(veh)
                    local panelOffsetX = 0.0
                    local panelOffsetY = 0.0
                    _DrawRect(0.85 + panelOffsetX, 0.89 + panelOffsetY, 0.26, 0.16, 16, 16, 16, 225, 0)
                    _DrawRect(0.85 + panelOffsetX, 0.835 + panelOffsetY, 0.245, 0.035, 0, 0, 0, 225, 0)
                    _DrawRect(0.85 + panelOffsetX, 0.835 + panelOffsetY, 0.24, 0.03, 186, 186, 186, 225, 0)
                    Draw("MAIN", 0, 0, 0, 255, 0.745 + panelOffsetX, 0.825 + panelOffsetY, 0.25, 0.25, 1, true, 0)
                    Draw("Advanced Lighting System", 0, 0, 0, 255, 0.92 + panelOffsetX, 0.825 + panelOffsetY, 0.25, 0.25, 1, true, 0)
                    _DrawRect(0.78 + panelOffsetX, 0.835 + panelOffsetY, 0.033, 0.025, 0, 0, 0, 225, 0)

                    -- Light Stage One
                    if AreWarningLightsActivated(veh) then
                        _DrawRect(0.815 + panelOffsetX, 0.835 + panelOffsetY, 0.033, 0.025, 0, 0, 0, 225, 0)
                        _DrawRect(0.78 + panelOffsetX, 0.835 + panelOffsetY, 0.03, 0.02, 199, 152, 0, 225, 0)
                        Draw("S-1", 0, 0, 0, 255, 0.78 + panelOffsetX, 0.825 + panelOffsetY, 0.25, 0.25, 1, true, 0)
                    else
                        _DrawRect(0.815 + panelOffsetX, 0.835 + panelOffsetY, 0.033, 0.025, 0, 0, 0, 225, 0)
                        _DrawRect(0.78 + panelOffsetX, 0.835 + panelOffsetY, 0.03, 0.02, 186, 186, 186, 225, 0)
                        Draw("S-1", 0, 0, 0, 255, 0.78 + panelOffsetX, 0.825 + panelOffsetY, 0.25, 0.25, 1, true, 0)
                    end

                    -- Light Stage Two
                    if AreSecondaryLightsActivated(veh) then
                        _DrawRect(0.815 + panelOffsetX, 0.835 + panelOffsetY, 0.03, 0.02, 199, 152, 0, 225, 0)
                        Draw("S-2", 0, 0, 0, 255, 0.815 + panelOffsetX, 0.825 + panelOffsetY, 0.25, 0.25, 1, true, 0)
                    else
                        _DrawRect(0.815 + panelOffsetX, 0.835 + panelOffsetY, 0.03, 0.02, 186, 186, 186, 225, 0)
                        Draw("S-2", 0, 0, 0, 255, 0.815 + panelOffsetX, 0.825 + panelOffsetY, 0.25, 0.25, 1, true, 0)
                    end

                    -- Light Stage Three [PRIMARY]
                    _DrawRect(0.850 + panelOffsetX, 0.835 + panelOffsetY, 0.033, 0.025, 0, 0, 0, 225, 0)
                    if ArePrimaryLightsActivated(veh) then
                        _DrawRect(0.850 + panelOffsetX, 0.835 + panelOffsetY, 0.03, 0.02, 199, 152, 0, 225, 0)
                        Draw("S-3", 0, 0, 0, 255, 0.850 + panelOffsetX, 0.825 + panelOffsetY, 0.25, 0.25, 1, true, 0)
                    else
                        _DrawRect(0.850 + panelOffsetX, 0.835 + panelOffsetY, 0.03, 0.02, 186, 186, 186, 225, 0)
                        Draw("S-3", 0, 0, 0, 255, 0.850 + panelOffsetX, 0.825 + panelOffsetY, 0.25, 0.25, 1, true, 0)
                    end

                    -- Warning Lights
                    _DrawRect(0.742 + panelOffsetX, 0.88 + panelOffsetY, 0.028, 0.045, 0, 0, 0, 225, 0)
                    if AreWarningLightsActivated(veh) then
                        _DrawRect(0.7421 + panelOffsetX, 0.871 + panelOffsetY, 0.026, 0.02, 199, 152, 0, 225, 0)
                        Draw("E - 00", 199, 152, 0, 255, 0.7423 + panelOffsetX, 0.88 + panelOffsetY, 0.25, 0.25, 1, true, 0)
                    else
                        _DrawRect(0.7421 + panelOffsetX, 0.871 + panelOffsetY, 0.026, 0.02, 186, 186, 186, 225, 0)
                        Draw("E - 00", 255, 255, 255, 255, 0.7423 + panelOffsetX, 0.88 + panelOffsetY, 0.25, 0.25, 1, true, 0)
                    end
                    Draw("WRN", 0, 0, 0, 255, 0.7423 + panelOffsetX, 0.86 + panelOffsetY, 0.25, 0.25, 1, true, 0)

                    -- Secondary Lights
                    _DrawRect(0.774 + panelOffsetX, 0.88 + panelOffsetY, 0.028, 0.045, 0, 0, 0, 225, 0)
                    if AreSecondaryLightsActivated(veh) then
                        _DrawRect(0.774 + panelOffsetX, 0.871 + panelOffsetY, 0.025, 0.02, 199, 152, 0, 225, 0)
                        Draw("E - 00", 199, 152, 0, 255, 0.774 + panelOffsetX, 0.88 + panelOffsetY, 0.25, 0.25, 1, true, 0)
                    else
                        _DrawRect(0.774 + panelOffsetX, 0.871 + panelOffsetY, 0.025, 0.02, 186, 186, 186, 225, 0)
                        Draw("E - 00", 255, 255, 255, 255, 0.774 + panelOffsetX, 0.88 + panelOffsetY, 0.25, 0.25, 1, true, 0)
                    end
                    Draw("SEC", 0, 0, 0, 255, 0.774 + panelOffsetX, 0.86 + panelOffsetY, 0.25, 0.25, 1, true, 0)

                    -- Primary Lights
                    _DrawRect(0.806 + panelOffsetX, 0.88 + panelOffsetY, 0.028, 0.045, 0, 0, 0, 225, 0)
                    if ArePrimaryLightsActivated(veh) then
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

                    -- SIREN TONES (4 independent tones)
                    _DrawRect(0.742 + panelOffsetX, 0.93 + panelOffsetY, 0.028, 0.045, 0, 0, 0, 225, 0)
                    Draw("--", 255, 255, 255, 255, 0.7423 + panelOffsetX, 0.93 + panelOffsetY, 0.25, 0.25, 1, true, 0)
                    Draw("WAIL", 0, 0, 0, 255, 0.7423 + panelOffsetX, 0.91 + panelOffsetY, 0.25, 0.25, 1, true, 0)
                    if sirenTone == 1 then
                        _DrawRect(0.7421 + panelOffsetX, 0.921 + panelOffsetY, 0.026, 0.02, 199, 152, 0, 225, 0)
                    else
                        _DrawRect(0.7421 + panelOffsetX, 0.921 + panelOffsetY, 0.026, 0.02, 186, 186, 186, 225, 0)
                    end

                    _DrawRect(0.774 + panelOffsetX, 0.93 + panelOffsetY, 0.028, 0.045, 0, 0, 0, 225, 0)
                    Draw("--", 255, 255, 255, 255, 0.774 + panelOffsetX, 0.93 + panelOffsetY, 0.25, 0.25, 1, true, 0)
                    Draw("YELP", 0, 0, 0, 255, 0.774 + panelOffsetX, 0.91 + panelOffsetY, 0.25, 0.25, 1, true, 0)
                    if sirenTone == 2 then
                        _DrawRect(0.774 + panelOffsetX, 0.921 + panelOffsetY, 0.026, 0.02, 199, 152, 0, 225, 0)
                    else
                        _DrawRect(0.774 + panelOffsetX, 0.921 + panelOffsetY, 0.026, 0.02, 186, 186, 186, 225, 0)
                    end

                    _DrawRect(0.806 + panelOffsetX, 0.93 + panelOffsetY, 0.028, 0.045, 0, 0, 0, 225, 0)
                    Draw("--", 255, 255, 255, 255, 0.806 + panelOffsetX, 0.93 + panelOffsetY, 0.25, 0.25, 1, true, 0)
                    Draw("PRIO", 0, 0, 0, 255, 0.806 + panelOffsetX, 0.91 + panelOffsetY, 0.25, 0.25, 1, true, 0)
                    if sirenTone == 3 then
                        _DrawRect(0.806 + panelOffsetX, 0.921 + panelOffsetY, 0.026, 0.02, 199, 152, 0, 225, 0)
                    else
                        _DrawRect(0.806 + panelOffsetX, 0.921 + panelOffsetY, 0.026, 0.02, 186, 186, 186, 225, 0)
                    end

                    _DrawRect(0.838 + panelOffsetX, 0.93 + panelOffsetY, 0.028, 0.045, 0, 0, 0, 225, 0)
                    Draw("--", 255, 255, 255, 255, 0.838 + panelOffsetX, 0.93 + panelOffsetY, 0.25, 0.25, 1, true, 0)
                    Draw("HI-LO", 0, 0, 0, 255, 0.838 + panelOffsetX, 0.91 + panelOffsetY, 0.25, 0.25, 1, true, 0)
                    if sirenTone == 4 then
                        _DrawRect(0.838 + panelOffsetX, 0.921 + panelOffsetY, 0.026, 0.02, 199, 152, 0, 225, 0)
                    else
                        _DrawRect(0.838 + panelOffsetX, 0.921 + panelOffsetY, 0.026, 0.02, 186, 186, 186, 225, 0)
                    end
                end
            end
        end
        Citizen.Wait(sleep)
    end
end)
