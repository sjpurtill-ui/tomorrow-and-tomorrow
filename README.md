# Tomorrow and Tomorrow

A Godot 4 grand-strategy prototype built around an organic province map.

## Run

Open this folder in Godot 4 and run the project.

## Current prototype

- 72 procedurally shaped provinces
- A newly seeded world on every launch, with continents and oceans
- Province and national borders
- Province hover and selection
- Pan and zoom controls
- Province adjacency with highlighted neighbors
- Terrain, population, and resource generation
- Country treasury and monthly income simulation
- A single starting settler with province-to-province movement

## Generative campaign director

Each new seeded campaign receives a founding mandate with conflicting success
conditions and starting pressures. If no API is configured, a deterministic
seeded director supplies a fully playable mandate.

To use an OpenAI-compatible generative endpoint, provide these environment
variables before launching Godot:

- `LEVIATHAN_AI_ENDPOINT` — full chat-completions endpoint
- `LEVIATHAN_AI_MODEL` — provider model identifier
- `LEVIATHAN_AI_API_KEY` — API credential (or use `OPENAI_API_KEY`)

The credential is read at runtime and is never written into the project. The
model may propose prose, goals, and a small vocabulary of pressures. All output
is validated and clamped before the deterministic consequence engine can apply
it; generated text cannot directly change population, resources, or code.

## Core consequence simulation

Population allocations now propagate through provision, health, effective
labor, construction, discovery, resource access, material capacity, logistics,
security, ecology, cohesion, legitimacy, and population growth. Council choices
and free-form orders map to bounded policies with explicit secondary effects.

Select a province containing an army, then right-click a neighboring friendly province to move. Number keys 0–4 control simulation speed.

## Combat simulation

`CombatSimulator` is a deterministic, presentation-free battle resolver. Its
first-pass model uses troop count, attack, defense, morale, readiness, and a
terrain defense modifier. A seed makes outcomes reproducible for tests, saves,
replays, and later multiplayer synchronization. It also accepts the existing
army `population` field as troop count, allowing the map layer to adopt it
without changing army data immediately.

The simulator returns a round-by-round battle record and does not mutate either
force. World-state consequences—casualties, retreat, province control, citizen
deaths, and historical records—remain an explicit integration step.

For safe manual experimentation, open `res://tools/battle_lab.tscn` in Godot
and run the current scene (F6). The Battle Lab is isolated from `GameState` and
cannot alter the campaign.
