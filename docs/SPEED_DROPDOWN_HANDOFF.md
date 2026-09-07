# Compact speed control — September 7, 2026

Worker: /Users/seanpurtill/Documents/Codex/tt-speed-dropdown
Branch: codex/speed-dropdown. Base: ad943db4657f63ba979920127053834e6380ecd9.
Owned: command_rail_hud.gd and six UI journey probes referencing the old buttons.

One dropdown replaces persistent 1–5 buttons, displaying the actual simulation
rate. A separate button pauses/resumes the last running speed. Keyboard 0–5 and
simulation rates are unchanged. The date no longer repeats the dropdown's speed;
the minimum text width is reduced. The representative time bar measures 380 px.
A reload guard rebuilds only the time control when an existing HUD receives the
new script. No campaign restart is required if live script reload is applied.

Clean isolated headless editor import passed. Temporary headless component check
passed all five speed selections, pause, resume at the previous speed, and width
below 430 px. Evidence: /tmp/speed-dropdown-import.log and
/tmp/speed-dropdown-check.log. The temporary runner was removed. Journey probes
now select the dropdown and emit its item_selected signal; those full campaigns
were not rerun for this UI-only change. No new simulation tests added.

No save fields or compatibility changes, no simulation changes, no shared hotspot
edits. The command rail is the only production file changed. Keep the existing
player running; do not restart it merely to display the change. Integration and
live application must be reported separately.
