Config = {}

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
    ["RAMP"] = {
        Pattern = 5
    }
}

Config.Patterns = {
    [1] = {
        Stages = {
            {Extras = {1, 2, 7}}, -- First Flash
            {Extras = {3, 4, 9}}  -- Second Flash
        },
        FlashDelay = 250
    },
    [2] = {
        Stages = {
            {Extras = {1, 3, 5, 7}}, -- First Flash
            {Extras = {2, 4, 6, 8}}  -- Second Flash
        },
        FlashDelay = 250
    },
    [3] = {
        Stages = {
            {Extras = {1, 2, 9}}, -- First Flash
            {Extras = {3, 4, 7}}  -- Second Flash
        },
        FlashDelay = 250
    },
    [4] = {
        Stages = {
            {Extras = {1, 3, 7}}, -- First Flash
            {Extras = {2, 4, 9}}  -- Second Flash
        },
        FlashDelay = 250
    },
    [5] = {
        Stages = {
            {Extras = {1, 3, 7}}, -- First Flash
            {Extras = {2, 4, 9}}  -- Second Flash
        },
        FlashDelay = 75
    }
}