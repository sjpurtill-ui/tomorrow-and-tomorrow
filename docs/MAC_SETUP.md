# Develop and play on a Mac

The repository is https://github.com/sean544/tomorrow-and-tomorrow and is private. Sign into an account with access; GitHub returns 404 to unauthenticated visitors. The publishing account on Windows is sean544. Do not make the repository public to fix authentication.

## Get the current game

Clone with your authenticated Git client, or use:

```sh
git clone https://github.com/sean544/tomorrow-and-tomorrow.git
cd tomorrow-and-tomorrow
git switch main
git pull --ff-only
```

Open `project.godot` in the standard Godot editor, allow asset imports to finish, and press F5. The configured main scene is `local_terrain.tscn`. F5 starts a new world unless you explicitly supply resume arguments. The PowerShell launcher is Windows-only; do not run it on your Mac.

The project declares Godot 4.7 and was validated on Windows with 4.7.2. It uses GDScript and the Compatibility renderer. No native extension or .NET runtime is required by the tracked game. Mac execution and performance have not been tested here. Check your Mac against [Godot's system requirements](https://docs.godotengine.org/en/stable/about/system_requirements.html).

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
