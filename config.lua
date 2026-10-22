Config = {}
Config.EnableDebugging = true -- Useful for editing the script
Config.DisableGameControls = false -- This will disable the default game controls (Q - Radio Wheel) [NOT USED CURRENTLY]
Config.VehicleUpdateTime = 60 -- How often the script will check for players vehicles (In Seconds)
Config.UseWMServerSirens = false -- https://github.com/Walsheyy/WMServerSirens

---------- In-Game Editor (/alseditor or F7) ----------
Config.EditorRequireAce = true -- true = only allowed players can open/use the editor. false = anyone can (not recommended)
Config.EditorAce = 'als.editor' -- Ace permission that unlocks the editor. Grant it in server.cfg, e.g.: add_ace group.admin als.editor allow
-- Players listed here can also use the editor, no server.cfg change needed.
-- Any identifier works: 'fivem:123456', 'license:abc...', 'discord:123...', 'steam:110000...'
-- (Shown in the server console when a player joins. Note: this file is also sent to players' games.)
Config.EditorAllowedPlayers = {
    -- 'fivem:000000',
}
Config.EditorDataFile = 'data/als_data.json' -- Saved edits; these override the Vehicles/Patterns below. Delete it to go back to this file


---------- ELS General Settings ----------

Config.ELSRange = 100.0
Config.ELSIntensity = 0.5
Config.PatternDistance = 250.0 -- Flash patterns only run on vehicles within this distance of your camera (performance)
Config.EnvLightDrawDistance = 120.0 -- Environment light glow only drawn within this distance of your camera (performance)
Config.AutoOff = false -- Automatically turn off lights when exiting the vehicle
Config.SirenAlwaysAllowed = false -- If true, sirens can be toggled even with no light stage active (matches Miss-ELS's Config.SirenAlwaysAllowed)

---------- ELS Siren Settings (WM Sirens: https://github.com/fk-1997/Server-Sided-Sounds-and-Sirens/blob/main/IDTABLE.md#table-with-soundbank-soundset-and-audiostring) ----------

Config.WMServerSirensAudioBank = 'dlc_serversideaudio/oiss_ssa_vehaud_lspd_new'
Config.WMServerSirensSoundSet = 'oiss_ssa_vehaud_lspd_new_soundset'

Config.SirenTones = {
    [1] = Config.UseWMServerSirens and 'oiss_ssa_vehaud_noose_old_siren_adam' or 'VEHICLES_HORNS_SIREN_1',            -- wail
    [2] = Config.UseWMServerSirens and 'oiss_ssa_vehaud_noose_old_siren_boy' or 'VEHICLES_HORNS_SIREN_2',             -- yelp
    [3] = Config.UseWMServerSirens and 'oiss_ssa_vehaud_noose_old_siren_charles' or 'VEHICLES_HORNS_AMBULANCE_WARNING',   -- priority/hi-lo
    [4] = Config.UseWMServerSirens and 'oiss_ssa_vehaud_noose_old_siren_david' or 'VEHICLES_HORNS_POLICE_WARNING',       -- priority/hi-lo
}

---------- ELS Vehicle Settings ----------
---------- LIGHTS: RED, BLUE, GREEN, AMBER, WHITE ----------

Config.Vehicles = {
    ["lspd1"] = {
        Pattern = 1,
        EnvironmentLights = {
            { Bone = "extra_1", Offset = vector3(0.0, 0.0, 0.0), Color = "red", Extras = {1,3} },
            { Bone = "extra_1", Offset = vector3(0.0, 0.0, 0.0), Color = "blue", Extras = {2,4} },
            { Bone = "extra_1", Offset = vector3(0.0, 0.0, 0.0), Color = "white", Extras = {3,4} },
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
