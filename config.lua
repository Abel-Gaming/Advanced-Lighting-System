Config = {}
Config.EnableDebugging = false -- Useful for editing the script
Config.DisableGameControls = false -- This will disable the default game controls (Q - Radio Wheel) [NOT USED CURRENTLY]
Config.VehicleUpdateTime = 60 -- How often the script will check for players vehicles (In Seconds)
Config.UseWMServerSirens = false -- https://github.com/Walsheyy/WMServerSirens

---------- ELS General Settings ----------

Config.ELSRange = 150.0
Config.ELSIntensity = 0.5
Config.AutoOff = false -- Automatically turn off lights when exiting the vehicle
Config.SirenAlwaysAllowed = false -- If true, sirens can be toggled even with no light stage active (matches Miss-ELS's Config.SirenAlwaysAllowed)

---------- ELS Siren Settings ----------

Config.SirenTones = {
    [1] = Config.UseWMServerSirens and 'SIREN_ALPHA' or 'VEHICLES_HORNS_SIREN_1',            -- wail
    [2] = Config.UseWMServerSirens and 'SIREN_DELTA' or 'VEHICLES_HORNS_SIREN_2',             -- yelp
    [3] = Config.UseWMServerSirens and 'SIREN_BRAVO' or 'VEHICLES_HORNS_AMBULANCE_WARNING',   -- priority/hi-lo
    [4] = Config.UseWMServerSirens and 'SIREN_ECHO' or 'VEHICLES_HORNS_POLICE_WARNING',       -- priority/hi-lo
}

---------- ELS Vehicle Settings ----------
---------- LIGHTS: RED, BLUE, GREEN, AMBER, WHITE ----------

Config.Vehicles = {
    ["LCEMS"] = {
        Pattern = 1,
        EnvironmentLights = {
            { Bone = "extra_1", Offset = vector3(0.0, 0.0, 0.0), Color = "red", Extras = {1,2} }, -- You can use OpenIV to get bone ID's for where the lights generate from
            { Bone = "extra_2", Offset = vector3(0.0, 0.0, 0.0), Color = "white", Extras = {3,4} },
        }
    },
    ["FBI2"] = {
        Pattern = 1,
        EnvironmentLights = {
            { Bone = "extra_1", Offset = vector3(0.0, 0.0, 0.0), Color = "red", Extras = {1,2} }, -- You can use OpenIV to get bone ID's for where the lights generate from
            { Bone = "extra_3", Offset = vector3(0.0, 0.0, 0.0), Color = "blue", Extras = {3,4} },
            { Bone = "extra_7", Offset = vector3(0.0, 0.0, 0.0), Color = "amberq", Extras = {7,9} },
        }
    },
}

---------- ELS Pattern Settings ----------

Config.Patterns = {
    [1] = {
        Primary = {
            {Extras = {1,2}}, -- First Flash
            {Extras = {3,4}}, -- Second Flash
        },
        Secondary = {
            {Extras = {1}}, -- First Flash
            {Extras = {4}}, -- Second Flash
        },
        Warning = {
            {Extras = {7,9}},
            {Extras = {8}}
        },
        FlashDelay = 250
    },
}
