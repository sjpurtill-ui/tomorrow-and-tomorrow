# Tomorrow and Tomorrow

A Godot 4.7 game in which the player is a living god to one people, from a
band of 120 at a fire (game year 0, about 5000 BC) through the ages that
follow. Twelve other peoples (6 to 36) live the same history by the same
rules; only their rulers' tempers differ. There is no victory and no defeat.

## Run

On Windows, launch only through `tools/launch_game.ps1` from this checkout
(see `AGENTS.md`). On the Mac clone, see `docs/MAC_SETUP.md`. The main scene
is `res://local_terrain.tscn`.

## What the game is

- **One ledger, stated odds, seeded rolls.** The engine decides every
  outcome from one consistent state and reports it with its numbers; the
  language model only tells what happened (`docs/ADJUDICATION.md`).
- **The people come first.** Nine kinds of work (food, searching, cutting
  and digging, building, making, carrying, learning, keeping and caring,
  keeping watch) are the main lever; each grows into a sector
  (`docs/PEOPLE_FIRST.md`). Keeping watch is the army.
- **One seat per people.** A people never founds separate towns; its seat
  grows into districts, a county, a state and a country (`scripts/one_seat.gd`).
- **The court.** One screen (F12) for every conversation: summon officials
  or anyone they name, give orders by office buttons or in your own words,
  answer envoys. Online, a model reads the words and voices the court;
  offline, the same engine runs from choices.
- **Standing.** Nine strengths, how other peoples see us, and how our own
  people love and dread their god (`docs/STANDING_DESIGN.md`).
- **War.** The ruler sets how many keep watch, how many stay home, who leads
  and a stance toward each people; generals do the rest
  (`docs/GENERAL_CAMPAIGN_DESIGN.md`). Small peoples feud; grown ones war.
- **Research** comes only from people set to learning, with no cap; it costs
  goods and people taken from other work.

## Population scale contract

Population is stored and simulated only as authoritative numeric cohort
counts. The game never creates one runtime object, name, household
membership, pregnancy record, soldier ID, building, or UI row per human. The
same six age cohorts and four reproductive stages represent 120 people, one
billion people, or any scale between them. Government uses a small capped
pool of named public figures; ordinary citizens are never instantiated.
Settlement morphology is capped at 2,048 simulated plots, 1,024 routes and
128 nuclei. Work per tick may depend on the fixed number of cohorts, systems,
formations, districts, public officials or visible aggregate cells, never on
total population.

## The court's model connection

Set these before launching (the launcher copies them from the user
environment):

- `LEVIATHAN_AI_API_KEY` (or `OPENAI_API_KEY`): the API credential. It is read
  at runtime and never written into the project or a save.
- `LEVIATHAN_AI_MODEL`: the model, default `gpt-6-luna`.
- `LEVIATHAN_AI_ENDPOINT`: an OpenAI-compatible chat-completions endpoint;
  the official endpoint is used when only a key is given.
- `LEVIATHAN_AI_MODE`: `live` (default), `hybrid` or `offline`.

Model output is validated and clamped before the engine acts on it; generated
text never changes population, resources or code directly.

## Controls

Keys 0-5 set the pace (0 pauses; 4, a day a second, is the default). Mouse
wheel or Up/Down zoom through four distances and out to the globe; WASD or
middle-drag pan; Q/E rotate; N turns north up. F1-F11 open the rail's
sections, F12 the court, Esc backs out.

## Tests

gdUnit4 suites live in `tests/`; run one headless with
`<godot> --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests/<suite>.gd --ignoreHeadlessMode`.
The fast surrogate model of the civilization engine is in `tools/sim/`
(`docs/research/SURROGATE_SIM.md`).
