# ppsspp-patapon3-AHK-assist
An assist macro using AutoHotKey (AHK) v2 for Patapon3 Overhaul mod playing on PPSSPP emulator.

The macro inspect the game window, and it (almost) always hit perfect beats.

It was never meant to be a 500 lines macro but it is now. The code is super ugly and global variables are every where.
If you feel like it, feel free to contribute by fork and sending pull request.

I won't actively maintain this since this is just a practice project.

# Usage
Use AutoHotKey V2 to run the script. 
It should bring up a GUI window. Most gui components have a `?` button on the left that explains the behavior.
I also uploaded the prebuilt exe file but you should still build it yourselves.

It suports two modes: auto level and auto command.

Auto level mode will auto redo a level and auto command mode will repeatedly replay commands.

One note worthy thing is that the macro requires the PPSSPP window title to start with "PPSSPP". 

When the macro is running, the PPSSPP window has to be keep active at all time.
Clicking off the window (for example if you click on your web browser) will cause the macro to stop most of the time.
If the macro didn't stop, or clicking buttons stop working, then it is probably stucked in a loop somewhere.
I have break point in most places I can catch but if this still happens, you have to relaunch the macro.

The 2x speed toggle and mute toggle can be janky sometimes if you click around too much.

# Requirement/Setup

## Dependency

[https://github.com/buliasz/AHKv2-Gdip/blob/master/Gdip_All.ahk](https://github.com/buliasz/AHKv2-Gdip/blob/master/Gdip_All.ahk)

You need to download it and place it together with the script.

## AutoHotKey V2
Please see [https://www.autohotkey.com/](https://www.autohotkey.com/) for the download link.

## PPSSPP 

### keybinds
- `w` to `chika`
- `a` to `pata`
- `s` to `don`
- `d` to `pon`
- `g` to `start button`
- `t` to `turbo toggle`
- `m` to `mute toggle`
- `i` to `dpad up`
- `j` to `dpad left`
- `k` to `dpad down`
- `l` to `dpad right`

### Other Settings
- Alternative speed 1 should be 200% and alternative speed 2 should be disabled.
- The script is mostly tested under window size = 5x but anything between 1x to 10x should work (integer of course)

### Other note worthy setting I use
These are most likely not required but it is just what I use. Be careful about settings that changes frame rate.

#### Render mode
- The graphic backend is using Direct3D 11
- Render resolution is 1:1

#### Framerate control
- Vsync is OFF
- Frame skip is OFF
- Auto frameskip is OFF
- Speed hacks are all OFF
- Spline/Bezier curves quality is high

#### Performance
- Hardware transform is ON
- Software skinning is ON

#### Texture scaling
- Upscale type is xBRZ
- Everything else is OFF

#### Texture filtering
- Anisotropic filtering is 16x
- Texture filtering is AUTO
