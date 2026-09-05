# Manual city-assault baseline — isolated, not a release

Base canonical c89b895 / game2026.09.05.4. No combat, defense or aftermath mechanics changed. Scenario code and project settings only, on codex/city-defense-aftermath. Broader redesign paused at the user's request.

Seed74017. Player home10000,180 trained levy with improvised equipment, full initial condition, drill.65, morale.85, supplied. Enemy polity3000; target600 residents, fortification.2, logistics.6,500 total polity military and target military allocation.25. Existing formula gives119 regular defenders. Rival knowledge.15 and readiness.65. At peace; Attack Now starts war by existing rules. Current occupation requirement about31.254 before capture, dynamically recomputed after capture. Exact fixture values are test-only omniscient setup; city report retains normal observed ranges.

Starts paused in the city report. Click ATTACK NOW to begin personally. No round, conquest or aftermath is automatically played by the harness. Battle graphics uses existing manual round controls. RESET TEST restarts the deterministic fixture, discarding test progress. Closing and reopening this scenario also resets it. No campaign is loaded; saves/settings use C:/Users/sjpur/AppData/Roaming/TomorrowAndTomorrow_CityAssault_Test. Never merge this project.godot into canonical main.

Existing limitations deliberately retained: no population-backed civilian muster; decisive victory captures control before assessing sustained garrison adequacy; existing aftermath bundles. These are the behaviors the user wants to observe before choosing changes.

Validation: hidden GPU --verify-setup confirms paused start,119 defenders, enabled Attack Now, empty battle and aftermath. No battle played. Screenshot artifacts/manual-assault-ready.png. Probe exited; two ObjectDB instances/one resource were reported in use at exit, no setup/runtime script errors. Campaign quicksave SHA256 remained4FF73952D6B50FD130B4AEC97BDE5B5EDC68A0058DC59ACF39F3A39DD1B047D5.
