Config = {}
Config.EnableDebugging = false -- Useful for editing the script
Config.DisableGameControls = true -- This will disable the default game controls (Q - Radio Wheel) [NOT USED CURRENTLY]
Config.VehicleUpdateTime = 60 -- How often the script will check for players vehicles (In Seconds)
Config.UseWMServerSirens = false -- https://github.com/Walsheyy/WMServerSirens

Config.Vehicles = {
    ["FBI"] = {
        Pattern = 1
    },
    ["FBI2"] = {
        Pattern = 2
    },
    ["POLICE"] = {
        Pattern = 3
    },
    ["POLICE2"] = {
        Pattern = 4
    },
    ["POLICE3"] = {
        Pattern = 4
    },
    ["SHERIFF2"] = {
        Pattern = 4
    },
    ["RAMP"] = {
        Pattern = 5
    },
}

Config.Patterns = {
    [1] = {
        Primary = {
            {Extras = {1,4}}, -- First Flash
            {Extras = {2,7}},  -- Second Flash
            {Extras = {3,9}},  -- Third Flash
            {Extras = {2,7}},  -- Fourth Flash
            {Extras = {3,9}},  -- Fifth Flash
        },
        Secondary = {
            {Extras = {4}}, -- First Flash
            {Extras = {3}}, -- Second Flash
            {Extras = {2}}, -- Third Flash
            {Extras = {1}}, -- Fourth Flash
        },
        Warning = {
            {Extras = {}}
        },
        FlashDelay = 250
    },

    [2] = {
        Primary = {
            {Extras = {1,3,5,7}},
            {Extras = {2,4,6,8}}
        },
        Secondary = {
            {Extras = {3,5}},
            {Extras = {4,6}},
        },
        Warning = {
            {Extras = {7}},
            {Extras = {8}}
        },
        FlashDelay = 250
    },

    [3] = {
        Primary = {
            {Extras = {1,2,9}},
            {Extras = {3,4,7}}
        },
        Secondary = {
            {Extras = {9}},
            {Extras = {8}},
            {Extras = {7}},
        },
        Warning = {
            {Extras = {1}},
            {Extras = {4}}
        },
        FlashDelay = 250
    },

    [4] = {
        Primary = {
            {Extras = {1,3,7}},
            {Extras = {2,4,9}}
        },
        Secondary = {
            {Extras = {9}},
            {Extras = {8}},
            {Extras = {7}}
        },
        Warning = {
            {Extras = {1}},
            {Extras = {4}}
        },
        FlashDelay = 250
    },
    
    [5] = {
        Primary = {
            {Extras = {1,4,5}},
            {Extras = {2,3,6}},
            {Extras = {1,4,5}},
            {Extras = {2,3,6}},
            {Extras = {1,2,5}},
            {Extras = {3,4,6}},
            {Extras = {1,2,5}},
            {Extras = {3,4,6}},
        },
        Secondary = {
            {Extras = {1}},
            {Extras = {2}},
            {Extras = {3}},
            {Extras = {4}}
        },
        Warning = {
            {Extras = {1}},
            {Extras = {4}}
        },
        FlashDelay = 250
    }
}
