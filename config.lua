Config = {}
Config.EnableDebugging = false -- Useful for editing the script
Config.DisableGameControls = false -- This will disable the default game controls (Q - Radio Wheel) [NOT USED CURRENTLY]
Config.VehicleUpdateTime = 60 -- How often the script will check for players vehicles (In Seconds)
Config.UseWMServerSirens = false -- https://github.com/Walsheyy/WMServerSirens

---------- ELS General Settings ----------

Config.ELSRange = 50.0
Config.ELSIntensity = 5.0

---------- ELS Siren Settings ----------
Config.SirenToneControl = 86
Config.SirenTones = {
    Primary = {
        Normal = Config.UseWMServerSirens and 'SIREN_ALPHA' or 'VEHICLES_HORNS_SIREN_1',
        Alt = Config.UseWMServerSirens and 'SIREN_DELTA' or 'VEHICLES_HORNS_SIREN_2',
    },
    Secondary = {
        Normal = Config.UseWMServerSirens and 'SIREN_DELTA' or 'VEHICLES_HORNS_SIREN_3',
        Alt = Config.UseWMServerSirens and 'SIREN_ALPHA' or 'VEHICLES_HORNS_SIREN_4',
    },
}

---------- ELS Vehicle Settings ----------

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
            { Bone = "extra_7", Offset = vector3(0.0, 0.0, 0.0), Color = "amber", Extras = {7,9} },
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
