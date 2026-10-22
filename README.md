# ALS – Advanced Lighting System

**ALS** is an emergency lighting and siren system for FiveM by **Abel Gaming**, inspired by [FiveM ELS by MrDaGree](https://github.com/MrDaGree/ELS-FiveM).
It flashes vehicle extras in configurable patterns, casts coloured light around the vehicle, plays siren tones, and keeps all of it in step for every player on the server. Vehicle setups and patterns can be edited **in game**, with a live preview, and saved for everyone.

![FiveM](https://img.shields.io/badge/FiveM-OneSync-orange) ![Lua](https://img.shields.io/badge/Lua-5.4-blue) ![Version](https://img.shields.io/badge/version-1.2-c79800)

---

## Features

### Lights
- **Three light stages:** Warning (S-1), Secondary (S-2) and Primary (S-3), which can run on their own or together.
- **Pattern-based flashing:** each stage is a list of steps, and each step turns on a set of vehicle extras for one flash delay.
- **Environment lighting:** red, blue, green, amber or white light is cast onto the ground and nearby walls from any vehicle bone, with an optional offset. It glows only while its matching extras are on.
- **Synced across players:** every player sees the same flash at the same moment, timed from the server's shared clock, so lights don't stutter or drift.
- **Light on performance:**
  - One loop drives every vehicle.
  - An extra is only changed when its state actually changes.
  - Bones and extras are looked up once, when the lights come on.
  - Patterns and glow only run within a set distance of your camera.
- **Late joiners see the lights:** if a vehicle comes into view with its lights already on, you'll see them.

### Sirens
- Four siren tones: **Wail, Yelp, Priority and Hi-Lo**. One plays at a time.
- Works with the default GTA sounds or with **[WM Server Sirens](https://github.com/Walsheyy/WMServerSirens)** (server-side audio).
- Sirens need Primary lights on, unless you turn on `Config.SirenAlwaysAllowed`.

### Control panel (HUD)
- An on-screen panel appears whenever you're in an emergency vehicle.
- It shows the active stages, headlights, lock state and the selected siren tone.
- Toggle it with `/ALSPanel`.

### In-game vehicle editor
- Open it with **F7** or `/alseditor`.
- **Vehicles tab:**
  - "+ This car" adds the car you're sitting in by its spawn name. "+ New" adds a car by typing its name.
  - Choose which flash pattern each vehicle uses.
  - Add, copy and remove environment lights, and set each one's bone, offset (right, forward, up), colour and the extras that make it glow.
  - The bone list only shows bones your current car actually has.
  - The selected light shows as a glowing marker on your car while you edit.
- **Patterns tab:**
  - Set the flash delay, and add, remove or reorder the steps for each stage.
  - Click any step, or an extra in it, to **hold that step steady on your car** so you can see exactly what it lights. "▶ Play pattern" goes back to normal flashing.
  - Shows which vehicles use each pattern.
- **Live preview:** changes show on your car as you make them. Only you see them until you save.
- **Test buttons:** turn S-1, S-2 and S-3 on and off without leaving the editor.
- **Look around:** releases the mouse so you can move the camera. Press F7 to come back.
- **Save:** sends your changes to the server, which updates every player right away. No restart needed.
- **Revert:** throws away unsaved changes. Closing the editor does the same.
- **Copy as Lua:** exports your setup in `config.lua` format.
- **Permission-locked:** only players with an ace permission, or players listed in the config, can open the editor or save. The server checks every save.

---

## Requirements

- A FiveM server with **OneSync enabled** (`set onesync on`). ALS uses entity state bags to sync lights and sirens.
- Vehicles with light **extras** (and bones, for environment lights) set up in their model files.

## Installation

1. Put the `ALS` folder in your server's `resources` folder.
2. Add this to `server.cfg`:
   ```cfg
   ensure ALS
   ```
3. Give yourself access to the editor, either in `server.cfg`:
   ```cfg
   add_ace group.admin als.editor allow
   ```
   or by adding your ID to `Config.EditorAllowedPlayers` in `config.lua` (see [Editor permissions](#editor-permissions)).
4. Restart the server.

---

## Default keys

All keys can be changed by each player in **Settings → Key Bindings → FiveM**.

| Key | Action |
|---|---|
| **Q** | Toggle Primary lights (S-3) |
| **K** | Toggle Secondary lights (S-2) |
| **J** | Toggle Warning lights (S-1) |
| **Left Alt** | Wail siren |
| **Y** | Yelp siren |
| **H** | Priority siren |
| **N** | Hi-Lo siren |
| **F7** | Open the ALS editor (or return to it after "Look around") |
| *Unbound* (F24) | Lock / unlock ALS controls |

> Pressing the active siren tone's key again turns the siren off. Turning Primary lights off also turns the siren off.

## Commands

| Command | Who | What it does |
|---|---|---|
| `/alseditor` | Players with editor access | Opens the in-game vehicle editor |
| `/ALSPanel` | Everyone | Shows or hides the on-screen control panel |
| `als_reload` | Server console | Reloads saved editor data from `data/als_data.json` and sends it to all players |
| `als_reset` | Server console | Clears saved editor data. Restart ALS afterwards to go back to `config.lua` |

The key bindings run these commands, which you can also bind yourself:
`AG-ALS-FiveM-Primary`, `AG-ALS-FiveM-Secondary`, `AG-ALS-FiveM-Warning`, `AG-ALS-FiveM-Siren1` to `AG-ALS-FiveM-Siren4`, `AG-ALS-FiveM-Lock`.

---

## Configuration

Everything lives in `config.lua`.

### General

| Setting | Default | Description |
|---|---|---|
| `Config.EnableDebugging` | `false` | Prints extra messages to the console, such as missing bones |
| `Config.VehicleUpdateTime` | `60` | How often (in seconds) auto-repair is turned off on vehicles players are driving, so toggling extras doesn't repair damage |
| `Config.UseWMServerSirens` | `false` | Use WM Server Sirens audio instead of the default GTA sirens |
| `Config.WMServerSirensAudioBank` | `'dlc_serversideaudio/…'` | WM audio bank to load |
| `Config.WMServerSirensSoundSet` | `'oiss_ssa_vehaud_lspd_new_soundset'` | WM sound set to use |
| `Config.SirenTones` | 4 tones | Sound names for Wail, Yelp, Priority and Hi-Lo |

### Lights

| Setting | Default | Description |
|---|---|---|
| `Config.ELSRange` | `100.0` | How far environment light reaches |
| `Config.ELSIntensity` | `0.5` | Environment light brightness |
| `Config.PatternDistance` | `250.0` | Patterns only run on vehicles within this distance of your camera |
| `Config.EnvLightDrawDistance` | `120.0` | Environment light only draws within this distance of your camera |
| `Config.AutoOff` | `false` | Turn lights and siren off when you get out of the vehicle |
| `Config.SirenAlwaysAllowed` | `false` | Allow sirens without Primary lights on |

### Editor

| Setting | Default | Description |
|---|---|---|
| `Config.EditorRequireAce` | `true` | Only allowed players can open the editor and save. Set to `false` to let anyone use it (not recommended) |
| `Config.EditorAce` | `'als.editor'` | The ace permission that unlocks the editor |
| `Config.EditorAllowedPlayers` | `{}` | Player IDs that can use the editor without an ace |
| `Config.EditorDataFile` | `'data/als_data.json'` | Where editor saves are stored |

### Vehicles

Each vehicle is keyed by its **spawn name**:

```lua
Config.Vehicles = {
    ["lspd1"] = {
        Pattern = 1,
        EnvironmentLights = {
            -- Bone: where the light comes from (find bone names with OpenIV)
            -- Offset: metres from the bone (right, forward, up)
            -- Color: red, blue, green, amber or white
            -- Extras: the light glows while any of these extras are on
            { Bone = "extra_1", Offset = vector3(0.0, 0.0, 0.0), Color = "red",  Extras = {1,3} },
            { Bone = "extra_1", Offset = vector3(0.0, 0.0, 0.0), Color = "blue", Extras = {2,4} },
        }
    },
}
```

### Patterns

Each step turns on its extras for `FlashDelay` milliseconds, then moves to the next step and loops:

```lua
Config.Patterns = {
    [1] = {
        Primary = {
            {Extras = {1,2}}, -- step 1
            {Extras = {3,4}}, -- step 2
        },
        Secondary = {
            {Extras = {1}},
            {Extras = {4}},
        },
        Warning = {
            {Extras = {7,9}},
            {Extras = {8}},
        },
        FlashDelay = 250
    },
}
```

---

## Editor permissions

A player can use the editor if **either** of these is true:

1. **They have the ace permission** (set in `server.cfg`):
   ```cfg
   add_ace group.admin als.editor allow
   add_principal identifier.fivem:123456 group.admin
   ```
2. **Their ID is listed in `config.lua`:**
   ```lua
   Config.EditorAllowedPlayers = {
       'fivem:123456',
       'discord:123456789012345678',
   }
   ```
   Any identifier type works (`fivem:`, `license:`, `discord:`, `steam:`), and capitals don't matter. Players' IDs show in the server console when they join.

> ⚠️ `config.lua` is also sent to every player's game, so the IDs in `EditorAllowedPlayers` can be seen by players. FiveM or Discord IDs are fine; avoid `license:` IDs.

Players without access can still use lights and sirens as normal; they just can't open the editor.

## How editor saves work

- Saves go to `data/als_data.json` and **override** `Config.Vehicles` and `Config.Patterns` from `config.lua`.
- Every save also writes `data/als_config_export.lua`, a `config.lua`-ready copy you can paste into your config.
- To go back to `config.lua`, delete `data/als_data.json` (or run `als_reset` in the server console), then restart ALS.

---

## Credits

- **Abel Gaming**: author
- **[MrDaGree](https://github.com/MrDaGree/ELS-FiveM)**: original FiveM ELS, which ALS is based on
- **[Walsheyy](https://github.com/Walsheyy/WMServerSirens)**: WM Server Sirens (optional)
