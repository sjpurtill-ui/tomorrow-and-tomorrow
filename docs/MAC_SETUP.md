# Develop and play on a Mac

The repository is https://github.com/sjpurtill-ui/tomorrow-and-tomorrow and is private, owned by your personal account `sjpurtill-ui`. Sign into that account on your Mac; GitHub returns 404 to unauthenticated visitors. Do not make the repository public to fix authentication.

## Get the current game

Clone with your authenticated Git client, or use:

```sh
git clone https://github.com/sjpurtill-ui/tomorrow-and-tomorrow.git
cd tomorrow-and-tomorrow
git switch main
git pull --ff-only
```

If you already cloned before the ownership transfer, update that clone instead:

```sh
git remote set-url origin https://github.com/sjpurtill-ui/tomorrow-and-tomorrow.git
git remote -v
git pull --ff-only
```

Open `project.godot` in the standard Godot editor, allow asset imports to finish, and press F5. The configured main scene is `local_terrain.tscn`. F5 starts a new world unless you explicitly supply resume arguments. The PowerShell launcher is Windows-only; do not run it on your Mac.

The project declares Godot 4.7 and was validated on Windows with 4.7.2. It uses GDScript and the Compatibility renderer. No native extension or .NET runtime is required by the tracked game. Mac execution and performance have not been tested here. Check your Mac against [Godot's system requirements](https://docs.godotengine.org/en/stable/about/system_requirements.html).

### Main map zoom

With the pointer over the map, spread two fingers to zoom in or pinch them together to zoom out. Vertical two-finger scrolling also zooms; its direction follows the Mac's scrolling preference. Scrolling over a panel stays with that panel. Mouse-wheel zoom remains available.

Keyboard fallback: `=` or `+` zooms in; `-` zooms out, centered on the view. The numeric keypad's `+` and `-` also work. Hold a key to keep zooming, or hold Shift for faster scrolling/key zoom. Keyboard zoom is inactive while typing in a text field or using Command/Control/Option shortcuts.

After updating the input code, save and exit the running game normally, then relaunch the project to load the new controls. An already-running game retains its old scripts.

## Included and local dependencies

The terrain textures, exported unit assets, opening artwork, Tomorrow.mp3 and War.mp3 are included as regular Git files. No Git LFS objects are currently used. Godot regenerates `.godot/` and import caches. `art_source/.gdignore` keeps the source Blender file out of automatic Godot imports; the game loads the included GLB exports instead. Blender is needed only to rebuild source artwork, not to play.

The included Godot AI and gdUnit editor plugins are development tools. The game does not need an MCP server to play. The Windows probe/launcher scripts are not portable Mac launchers.

Live AI dialogue requires your own local `OPENAI_API_KEY` or `LEVIATHAN_AI_API_KEY` environment configuration and the game's AI setting enabled. Launch Godot from the configured environment if Finder does not inherit it. No credential is committed. AI-off play and supported explicit commands remain available.

## Bring a save separately

Saves are not part of Git. After saving normally, transfer desired `.save` files privately from:

`C:/Users/sjpur/AppData/Roaming/Godot/app_userdata/Tomorrow and Tomorrow/saves/`

to:

`~/Library/Application Support/Godot/app_userdata/Tomorrow and Tomorrow/saves/`

Create the destination folder if needed. These paths follow [Godot's user-data convention](https://docs.godotengine.org/en/stable/tutorials/io/data_paths.html). `quicksave.save` is the ordinary world; `river_war.save` is the general campaign. Keep a separate backup before loading on another machine. Do not commit private saves to Git. Use the game's Load control, or launch the Godot executable with `--path /path/to/clone -- --resume-saved` for the ordinary quicksave. Omit that argument for a fresh world.

## Keep development organized for the next two weeks

Designate the Mac clone as that machine's canonical checkout. Use one integrator and `codex/<task>` worktrees for feature work; preserve unrelated edits. Pull before starting, commit intentional files, run relevant checks, then push normally. Do not force-push shared main or copy whole project folders over another checkout. See `WORKER_HANDOFF.md` for the shared workflow. Absolute Windows paths in older instructions identify the Windows installation, not where to install on your Mac.

Unfinished work is reported separately from integrated main. Never assume a running game has loaded newly pulled scripts: exit it normally and run F5 again after an integration.
