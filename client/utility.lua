-- LIGHTS
PrimaryLightsActivated = false
SecondaryLightsActivated = false
WarningLightsActivated = false

-- SIRENS
PrimarySirenActivated = false
PrimarySirenID = nil
SecondarySirenActivated = false
SecondarySirenID = nil

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
    DisableActiveExtras()
    RegisterKeyMapping('AG-ALS-FiveM-Primary', 'Toggle Primary Lights', 'KEYBOARD', 'Q')
    RegisterKeyMapping('AG-ALS-FiveM-Secondary', 'Toggle Secondary Lights', 'KEYBOARD', 'K')
    RegisterKeyMapping('AG-ALS-FiveM-Warning', 'Toggle Warning Lights', 'KEYBOARD', 'J')
    RegisterKeyMapping('AG-ALS-FiveM-Lock', 'Lock ALS', 'KEYBOARD', 'F24')
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