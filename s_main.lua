----- PRIMARY SIREN -----
RegisterServerEvent('ALS:PlayPrimarySirenServer')
AddEventHandler('ALS:PlayPrimarySirenServer', function(netId)
    if not netId then return end
    TriggerClientEvent('ALS:PlayPrimarySirenClient', -1, netId)
end)

RegisterServerEvent('ALS:StopPrimarySirenServer')
AddEventHandler('ALS:StopPrimarySirenServer', function(netId)
    if not netId then return end
    TriggerClientEvent('ALS:StopPrimarySirenClient', -1, netId)
end)

----- SECONDARY SIREN -----
RegisterServerEvent('ALS:PlaySecondarySirenServer')
AddEventHandler('ALS:PlaySecondarySirenServer', function(netId)
    if not netId then return end
    TriggerClientEvent('ALS:PlaySecondarySirenClient', -1, netId)
end)

RegisterServerEvent('ALS:StopSecondarySirenServer')
AddEventHandler('ALS:StopSecondarySirenServer', function(netId)
    if not netId then return end
    TriggerClientEvent('ALS:StopSecondarySirenClient', -1, netId)
end)

----- SIREN TONE SWITCH -----
RegisterServerEvent('ALS:SetSirenToneServer')
AddEventHandler('ALS:SetSirenToneServer', function(netId, sirenType, alt)
    if not netId then return end
    TriggerClientEvent('ALS:SetSirenToneClient', -1, netId, sirenType, alt)
end)

----- FAST EXTRAS PUSH -----
RegisterServerEvent('ALS:SetExtrasServer')
AddEventHandler('ALS:SetExtrasServer', function(netId, extraIds, state)
    if not netId or not extraIds then return end
    TriggerClientEvent('ALS:SetExtrasClient', -1, netId, extraIds, state)
end)

-- NOTE: 'ALS:TogglePrimaryLights' / 'ALS:ToggleSecondaryLights' /
-- 'ALS:ToggleWarningLights' / 'ALS:DisableLights' relays have been removed.
-- They forwarded a raw client-side entity handle to every other client via
-- TriggerClientEvent(-1, ...), which is not a valid cross-client reference
-- and was the root cause of lights/extras misbehaving for other players.
-- See cl_events.lua for the full explanation - lights are now handled
-- locally on the driving client only, and sync automatically as part of
-- the game's normal vehicle network sync.
