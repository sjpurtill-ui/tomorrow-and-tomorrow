# Develop and play on a Mac

## Play the standalone release

For ordinary play on the canonical Mac, run:

```sh
cd /Users/seanpurtill/Documents/Codex/tomorrow-and-tomorrow
python3 tools/launch_game_macos.py
```

This builds and opens a real macOS release app from integrated `main`, with no editor window, embedded game toolbar or debugger. It starts a fresh world by default; add `--resume-saved` to load quicksave. Exit the current game normally before relaunching. The launcher refuses another active player, a noncanonical checkout, uncommitted tracked changes or test overrides. It prints the source revision, app path, player PID and log path.

Install the official Godot export templates matching the installed editor before the first build. The Mac currently has the verified 4.7.2 macOS template. Builds are kept under `artifacts/macos-release/<commit>/Tomorrow and Tomorrow.app`; rebuilding uses the release preset and verifies the local ad-hoc signature. This is a local build, not a notarized distribution. The release template loads its bundled game and rejects `--path`; the absolute app executable path and build marker identify the canonical source. The editor workflow below is for development.

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

### Display, sound and quitting

Open **Menu** (or Escape from the map), then scroll to **Display & Performance**. Text & interface size offers 100–175%; the logical canvas adapts to the window and display density, with a minimum usable canvas so controls remain reachable. The default is 125%, substantially larger than the previous 1920×1080 interface squeezed into a 1280×720 window. Long menus scroll; compact management docks temporarily hide the map toolbar and notification queue to avoid overlap.

3D resolution offers 50%, 75% (default), and 100%. It scales only the 3D image, preserving sharp UI text. Terrain shadows default off and can be enabled. Frame limits of 30, 60 (default), or 120 reduce unnecessary rendering; these are ceilings, not promised frame rates. Map snapshots refresh at ten updates per second while camera input and simulation time remain independent. These changes reduce measured CPU work but do not establish a particular GPU frame rate on every world.

The **Music volume** slider applies immediately to the score, including both tracks. Zero mutes music; effects are unchanged. Display and music preferences are stored locally in `user://display.cfg`, separately from world saves, and persist across launches.

**Quit Game…**, Command-Q, and the window close control open a confirmation with **Save & Quit**, **Keep Playing**, and **Quit Without Saving**. Save & Quit stays open and reports an error if saving fails. Quit Without Saving explicitly discards progress since the last save. Installing these changes requires one relaunch; subsequent settings changes apply immediately.

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
