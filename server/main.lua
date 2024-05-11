----- PRIMARY SIREN -----
RegisterServerEvent('ALS:PlayPrimarySirenServer')
AddEventHandler('ALS:PlayPrimarySirenServer', function(vehicle)
    TriggerClientEvent('ALS:PlayPrimarySirenClient', -1, vehicle)
end)

RegisterServerEvent('ALS:StopPrimarySirenServer')
AddEventHandler('ALS:StopPrimarySirenServer', function(vehicle)
    TriggerClientEvent('ALS:StopPrimarySirenClient', -1, vehicle)
end)

----- SECONDARY SIREN -----
RegisterServerEvent('ALS:StopSecondarySirenServer')
AddEventHandler('ALS:StopSecondarySirenServer', function(vehicle)
    TriggerClientEvent('ALS:StopSecondarySirenClient', -1, vehicle)
end)

RegisterServerEvent('ALS:PlaySecondarySirenServer')
AddEventHandler('ALS:PlaySecondarySirenServer', function(vehicle)
    TriggerClientEvent('ALS:PlaySecondarySirenClient', -1, vehicle)
end)

----- PRIMARY LIGHTS -----
RegisterServerEvent('ALS:TogglePrimaryLights')
AddEventHandler('ALS:TogglePrimaryLights', function(vehicle, vehicleConfig)
    TriggerClientEvent('ALS:TogglePrimaryLights', -1, vehicle, vehicleConfig)
end)

----- SECONDARY LIGHTS -----
RegisterServerEvent('ALS:ToggleSecondaryLights')
AddEventHandler('ALS:ToggleSecondaryLights', function(vehicle, vehicleConfig)
    TriggerClientEvent('ALS:ToggleSecondaryLights', -1, vehicle, vehicleConfig)
end)

----- WARNING LIGHTS -----
RegisterServerEvent('ALS:ToggleWarningLights')
AddEventHandler('ALS:ToggleWarningLights', function(vehicle, vehicleConfig)
    TriggerClientEvent('ALS:ToggleWarningLights', -1, vehicle, vehicleConfig)
end)

----- DISABLE LIGHTS -----
RegisterServerEvent('ALS:DisableLights')
AddEventHandler('ALS:DisableLights', function(vehicle)
    TriggerClientEvent('ALS:DisableLights', -1, vehicle)
end)