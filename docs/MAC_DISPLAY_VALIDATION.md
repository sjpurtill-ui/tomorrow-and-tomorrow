# Mac input, display and performance validation

Base: `7fb7e96`. Worktree: `codex/mac-trackpad-zoom`. Godot: standard 4.7.2, Apple M1 Pro, Compatibility renderer.

## Changes

Native pan and magnify gestures use the map's accumulated smooth zoom; UI controls retain their gestures. Keyboard `+`/`=`/`-` and keypad equivalents are the fallback, with Shift acceleration and text-focus/modifier guards.

Map report/marker/settlement snapshots refresh at 10 Hz instead of every rendered frame. Camera input, smoothing and world simulation retain their existing timing. Snapshot presentation can lag by up to 100 ms; this does not postpone simulation events. Display preferences control only rendering, UI scaling and music. Defaults are 125% interface size, 75% 3D resolution, no terrain shadows, and a 60 fps ceiling. UI scaling adapts to display density and caps enlargement to maintain a 1024×640 logical canvas. Menus scroll rather than shrinking their text.

Quit confirms save/discard/cancel. Save failure prevents exit. Save writes use a temporary sibling file, check the write, then replace the old save. Payload and slot formats are unchanged. Music is routed through its own bus; both score tracks retain their existing per-track gain and schedule.

## Reproducible checks

Run from an isolated checkout with a separate application name in ignored `override.cfg` when using graphical tests. The validation here used `Tomorrow and Tomorrow Mac QA`. Tests never load a player save. Display preference and save-writer tests write only under ignored `artifacts/`; quit tests stub save/exit.

```sh
Godot --headless --path /path/to/worktree --scene res://tests/trackpad_zoom_probe.tscn --quit-after 600
Godot --headless --path /path/to/worktree --scene res://tests/mac_performance_probe.tscn --quit-after 600
Godot --headless --path /path/to/worktree --scene res://tests/mac_display_probe.tscn --quit-after 600
Godot --path /path/to/worktree --scene res://tests/mac_display_probe.tscn --audio-driver Dummy --quit-after 600 -- --capture-display
```

Trackpad probe: 24 checks, including actual viewport event routing, UI gesture delivery, focus, modal gates, opposite/neutral gestures and retained wheel controls.

Display probe: 1280×720 and 1440×900 windows at all four UI sizes; modal, rail, time controls and Military dock bounds; scroll accessibility; native canvas vs reduced 3D scale; shadow/frame-limit settings; music routing, mute and persisted preferences; save replacement/write failure; save-before-quit, failure, explicit discard, cancellation and Command-Q.

## CPU evidence and limits

A fresh-world paused fixture measured the army marker snapshot at roughly 2–3 ms per call despite having no field army. After warming terrain jobs, three alternating batches in the same process measured these costs for 120 calls to the normal map process function:

| Schedule | CPU milliseconds | Snapshot refreshes |
| --- | --- | --- |
| Every frame | 556.809 / 666.870 / 605.108 | 120 each |
| 10 Hz | 134.062 / 182.115 / 145.431 | 19 each |

Elapsed world day and population were unchanged in this paused test. These are CPU workload measurements, not achieved frame rates. They do not measure an old campaign, GPU cost, sustained thermal behavior, or every settlement scale. Reducing 3D resolution and disabling shadows reduces rendering work; graphical validation checks the controls and layout, not a promised FPS gain. Native physical trackpad behavior still merits a user check after relaunch; synthetic Godot gesture routing is covered.

The user paused campaign redesign. No campaign entry, world-reset, faction, army, progression or gameplay changes are included. The existing pre-scenario backup was inspected only for existence and remains untouched. Canonical integration and relaunch belong to the integrator; do not copy the test `override.cfg` or generated artifacts.
