# Conceived wonders and their rewards

The binding design is `docs/GREAT_WORKS_DESIGN.md` (Revision 2). There is no
fixed list of wonders and no world-unique claim: any people may conceive and
attempt as many works as it can sustain.

## Conception (`scripts/wonder_concept.gd`)

A wonder is composed from a bounded grammar — **form** (ring, mound, stair,
tower, hall, cistern, granary, bridge, causeway, dam, colossus, garden,
observatory, gate, canal, archive, amphitheatre, lighthouse) × **purpose**
(honor the dead, bind the people, tame the waters, end hunger, watch the heavens,
awe rivals, keep knowledge, welcome strangers, show mastery, defy the heavens,
mark a triumph, give thanks) × **ambition** (modest, grand, audacious) ×
**material** (earth, timber, stone, brick, iron, poured stone). Forms and
materials are gated by known discoveries; scale and cost grow with the people's
engineering tier. Purposes are weighted by societal values, present needs and
fears (hunger, thirst, division) and a trigger (famine, flood, war, victory,
death, anniversary, discovery, envy, plenty, expand). Each concept gets a unique
name in the people's naming tradition, a lore line and a motive. Everything is
deterministic from world seed, owner, day and trigger. The concept id encodes
the design (`wonder:<form>:<purpose>:<ambition>:<material>:<tier>:<token>`), so
any system can rebuild its definition. A ruler's words map onto the grammar by
keywords; an optional model mapping is bounded to the same grammar.

## Feasibility and outcome

Before and during construction, feasibility weighs engineering capability
(tier, material quality, architect talent, crafters, builders) against the
ambition's demand, plus social support (cohesion, legitimacy, food, war). It is
spoken in-world by the builders, never shown as a bare percentage. Stage-gate
decisions and construction events shift it. On completion the outcome is drawn
deterministically: **triumph**, **success**, **flawed** (stands diminished, never
fully recovers), or **collapse** — a named folly: materials lost, cohesion and
legitimacy fall, people die, officials remember the shame, and the ruin carries
its own lore (its stone can be quarried). Withdrawing support leaves an
**abandoned** site. Audacious works fail far more often and pay far more.

## Payoff

Purpose maps to an effect family — civic steadiness, famine reserve (Covenant),
forecasting (Watching Sky), memory keeping (Long Song), deterrence, traffic —
plus practical rewards (storage, spoilage, research, crafting, attraction,
reputation), all scaled by ambition × outcome and bounded by the existing caps.
Successful works add allure; dedication ceremonies bring foreign envoys whose
gifts come from their real stores. Raising a new work on an existing site
layers it: the earlier work, its name and history are kept. Captured works
serve their occupier.

The twelve founding definitions (Ancestors' Ring, Hall of Many Hearths, …)
remain only so older saves keep loading and functioning with their original
rewards.

## History, not victory

There is no victory in this game. A people's wonders are remembered as history
and reputation: the panel records works attempted, how many stood, how many
fell as follies, those standing now, those that endured twenty years, the kinds
of purpose among them, and how many foreign peoples know of them. Older saves
that carry a retired "wonder_victory" award still load; it is ignored and never
written.

## Saves

Existing undertaking records load unchanged (legacy ids resolve through the
founding definitions; missing fields are added lazily; gates already passed are
not re-posed). New fields — concept, outcome, feasibility, shift, rewards,
effect, scar, ruin lore, layers, rivalry — are optional and validated.
