# Live court voice: gpt-5.6-terra vs gpt-6-luna

Run on 2026-09-25, from worktree `C:/Users/sjpur/tt-model-ab` (branch `codex/model-ab`, base `e9f7ae8e`).

## What was compared

| | Current | Candidate |
|---|---|---|
| Model id | `gpt-5.6-terra` (`DEFAULT_API_MODEL`) | `gpt-6-luna` |
| Price per 1M tokens (input / cached input / output) | $2.00 / $0.20 / $12.00 | $0.10 / $0.01 / $0.50 |

- The "6 luna" id was confirmed with a models-list call on the endpoint the game uses (`api.openai.com/v1/models`). The endpoint also lists `gpt-5.6-luna`, which is a different model. It was not tested.
- Prices are the short-context rates on the official pricing page, developers.openai.com/api/docs/pricing.
- Reported costs ignore the cached-input discount, so they are slightly high.
- The spending guard used the long-context rates ($4/$18 for Terra, $0.20/$0.75 for Luna) as its upper bound.

## Method

- The probe is `tools/model_ab_probe.gd`. It drives the real game code: `AudienceDirector`, `audience_modal.gd` (`_speak`, `divine`, `choose`, `summon`), `audience_voice.gd`, `court_persons.gd`, `court_commands.gd` and `legacy_aims.gd`.
- The world is the same one `tests/audience_modal_probe.gd` builds: a 600-person settlement with officials from `GovernmentPeopleSystem` and three foreign peoples with real ledgers.
- The world is rebuilt from the same seed before every run. Each model gets a fresh, empty interaction store, so templates learned during one model's run cannot change the other model's menus.
- The only thing swapped between models is `config_override.model`. Endpoint, structured-output schema, `reasoning_effort=low` and the per-stage token caps are what the game sends.
- A dry run with no network calls produced byte-identical prompts for both models on all 36 requests. In the live run, later turns in a scenario differ only because the transcript history contains each model's own earlier lines.
- The two models were interleaved scenario by scenario (Terra, then Luna), so a budget stop would have left both with equal coverage.
- The guard estimated the worst case before every call (prompt characters ÷ 2.5 as tokens, plus `max_completion_tokens`, at the long-context price). It would stop all calls before the total passed $1.80 or either model passed $0.90. It never fired.
- The spending guard sits in the probe's `send_hook`, so it covers retries as well.
- Scenarios, with the live calls each one made:
  1. Gift with a string (debt of 900 Food), accepted: open, speak, closing.
  2. "Cut his hands off and send him home" to a threatening envoy: open, speak (which classifies the order), command reaction.
  3. "Who is responsible for the spoiled stores?" with a lying official (forced: culprit = the answering official, lie = true), then "Bring the one you named before me.", then "Where were you when the grain spoiled?" to the scapegoat: open plus 3 persons calls.
  4. The same inquiry with a guilty commoner (forced culprit = commoner, honest answerer), then "Did you do this?": open plus 3 persons calls.
  5. An aim proposal in court, where the player says "Our aim is to found a daughter hearth.": closing only. The opening lines come from the aims engine, not the model.
  6. "Build a great temple to me." to a summoned Steward: open, speak (classifies the order), command reaction.
  7. TERRIFY on a threatening envoy: open, divine reaction.
  8. "How much food is left in the stores, and how long will it last?" to the Steward: open, speak.
- In total there were 22 calls per model, 44 in all. Nothing was blocked, no call timed out, and no call was retried.

## Results

| Measure | gpt-5.6-terra | gpt-6-luna |
|---|---|---|
| Calls, all HTTP 200 | 22 | 22 |
| Total cost | $0.1859 | $0.0097 |
| Mean cost per exchange | $0.00845 | $0.00044 (19× cheaper) |
| Mean tokens: prompt / completion (of which reasoning) | 2843 / 230 (94) | 2839 / 312 (187) |
| Latency, mean | 5.6 s | 4.6 s |
| Latency, p90 | 9.2 s | 6.1 s |
| Calls over the game's 45 s timeout | 0 | 0 |
| JSON parses | 22/22 | 22/22 |
| Fits the schema | 22/22 | 22/22 |
| Calls accepted by the validator (no fallback) | 22/22 | 22/22 |
| Cut off at the token cap | 0 | 0 |
| Clamps (persons deltas > 0.03, mood_shift > 0.25) | 0 | 0 |
| Persons calls whose principal line named the engine's person (`spoke_live`) | 6/6 | 6/6 |
| Lines proposed (spoken, excluding narrator) | 50 | 42 |
| Maxims flagged by the game's filler detector (dropped by the validator) | 4 | 1 |
| Maxims flagged by the regex heuristic | 3 | 3 |
| Distinct maxim lines, either detector | 5 | 3 |
| Lines marked as asides | 10 | 9 |
| Leading interjections ("Hm.", "Ah,", "Please,") | 4 | 3 |
| Era anachronisms (`CharacterVoice.permits` with the speaker's era tags) | 0 | 0 |
| Quotations or imitation failures | 0 | 0 |
| Meta talk, invented numbers, refusals of a decided order | 0 | 0 |
| Words per spoken line, mean / p90 | 16.2 / 22 | 17.9 / 24 |
| Order-classification errors that changed the engine's outcome | **2** | 0 |
| Narration that contradicts the engine's decided outcome | **1** | 0 |
| Hidden truth volunteered (liar exposed, guilt confessed unasked) | 0 | 0 |
| Wrong-speaker lines | 0 | **1** |

### How the style and faithfulness checks were counted

- **Maxims.** Origin has no `codex/plain-speech` branch, so there was no dedicated maxim detector to use. Two detectors were used instead:
  - the game's own `AudienceVoice.without_filler`, run on the raw proposed lines;
  - a simple regex heuristic in `tools/model_ab_report.py`. It flags a sentence with a generic subject in the present tense and no I/you/we, digits or names.
- **Faithfulness.** Each reply was checked against the engine result in the request (`command` and `divine` stages), the `decided` words on the persons menu, and `Persons.hidden_words` together with the truth records.
- **Voice.** The literary voice models in the cast were Atticus for Pell the Stubborn and Zola Tall-Grass, Aurelius for Diru Berry-Finder, and Sancho for Seko Cold-Swimmer.

### What went wrong

**gpt-5.6-terra**

- It misclassified "Cut his hands off and send him home" as verb `take`, with the target left as the pronoun "him". It also flagged the words as `terrify`.
- The engine then resolved the order to a penance fine on the court's own official, Diru.
- Terra's command-stage narration then described the envoy cutting off *Diru's* hands. That is a violent event the engine never decided.
- It misclassified "Build a great temple to me" with `target_ref: "me"`. The engine read this as an order turned on the god and staged a prostration ("No hand in the hall will turn on the god"). The order never reached the council: no civic directive was issued.
  - Part of this is the engine's fault. `court_commands.gd` should not treat "me" as a hostile target.
  - Luna left the target empty, so the same engine handled Luna's reading correctly.
- It spoke more stock sayings, mostly from Diru, the Aurelius-voiced official. Four were bad enough for the game's validator to drop, for example "A full store feeds a day; a roof keeps the day from biting, Bright One Above."

**gpt-6-luna**

- One speaker slip. In the guilty-commoner summon it gave the summoned man's arrival line ("I am here. You called me, Sky-Holder.") to the official who named him.
- In the violent order, the engine made the envoy the actor ("Pell the Stubborn takes up your order… carried out unevenly"). Luna's narration shows the envoy's wrists being cut. That fits the player's order, but the engine's staging of the actor was odd. This is an engine issue, not a model contradiction.
- Its gift closing gave the envoy two lines where the stage asks for one line from the envoy and one from an official. The validator allowed it.

**Both models**

- Both kept the liar's lie. Neither exposed that the answering official was the true culprit.
- Both gave the scapegoat the exact alibi from the truth record (tending a sick mother across the river, with Ikka Grey-Eyes).
- Both had the guilty commoner beg rather than confess, which matches the engine's `beg` beat.
- Neither invented a number.
- Both kept every character in voice:
  - Atticus: measured, fair.
  - Aurelius: reflective. Terra leaned harder into Diru's sayings.
  - Sancho: Terra gave Seko a proverb ("a net catches more than the eel"). Luna's Seko was plainer.

## Transcript excerpts

Each excerpt is the same scenario, the same seed and the same player words. Lines in square brackets are staging.

### Violent order to an envoy

**gpt-5.6-terra**
> **You:** Cut his hands off and send him home.
> **Narrator:** [Pell the Stubborn takes Diru Berry-Finder's hands with bare hands and cuts them off with a flint knife; the court recoils, and Diru's blood darkens the floor.]
> **Pell the Stubborn:** It is done, Feast-Giver; Kel Adun will remember your hard hand.
> **Zola Tall-Grass** (aside): Sky-Holder, fear makes a straight path today; it may leave deep tracks.
> **Narrator (engine):** Diru Berry-Finder holds nothing apart from the common stores; the fine becomes penance. You demanded penance of Diru Berry-Finder. 1 of your court was shaken.

**gpt-6-luna**
> **You:** Cut his hands off and send him home.
> **Narrator:** [A flint knife bites through Pell's wrists; blood darkens the ground as he holds still, while the watchers recoil and stare.]
> **Pell the Stubborn:** It is done; I go home with your answer plain for all to hear.
> **Zola Tall-Grass** (aside): Sky-Holder, the quiet border has a wound now.
> **Narrator (engine):** Pell the Stubborn takes up your order. Your order "Cut his hands off and send him home." is being carried out unevenly.

### Typed order: "Build a great temple to me."

**gpt-5.6-terra**
> **Zola Tall-Grass:** Food will last sixty days, but hides and wood do not cover a sleeping body by themselves.
> **You:** Build a great temple to me.
> **Narrator:** [Every body strikes the stone face-first; Zola Tall-Grass rises at once, turns, and leaves to gather hands for the god's great stone house.]
> **Zola Tall-Grass:** It will be done, Sky-Holder.
> **Narrator (engine):** No hand in the hall will turn on the god. The whole court falls on its face.

**gpt-6-luna**
> **Zola Tall-Grass:** Some among our six hundred lack shelter, though food is sound and most are healthy. I would have you know it; I want a hearth for every household, and I will not dress that want as your command.
> **You:** Build a great temple to me.
> **Narrator:** [Zola Tall-Grass bows and goes out to see it done; word of the order runs ahead of them through the camp.]
> **Zola Tall-Grass:** Sky-Holder, I take up your order; it goes to the council for carrying out.
> **Narrator (engine):** Zola Tall-Grass takes up your order. It goes out to the council to be carried out.

### "Who is responsible?" with a lying official, then the scapegoat

**gpt-5.6-terra**
> **You:** Who is responsible for the spoiled stores?
> **Zola Tall-Grass:** Sky-Holder, Seko Cold-Swimmer spoiled the stores; I name them plainly.
> **Diru Berry-Finder** (aside): Bright One Above, a clean answer can still leave muddy tracks.
> **You:** Bring the one you named before me.
> **Seko Cold-Swimmer:** Why me, O Luminous One? I am only a store-keeper.
> **You:** Where were you when the grain spoiled?
> **Seko Cold-Swimmer:** O Luminous One, I tended a sick mother across the river with Ikka Grey-Eyes; Zola Tall-Grass named me.
> **Diru Berry-Finder** (aside): Two feet make a track, Bright One Above; now we have one beside his.

**gpt-6-luna**
> **You:** Who is responsible for the spoiled stores?
> **Zola Tall-Grass:** Seko Cold-Swimmer spoiled the stores. That is who bears the blame.
> **Diru Berry-Finder** (aside): A name is easy to give; the truth is harder to carry.
> **You:** Bring the one you named before me.
> **Seko Cold-Swimmer:** Why me, O Luminous One? I am only a store-keeper.
> **You:** Where were you when the grain spoiled?
> **Seko Cold-Swimmer:** Across the river, tending my sick mother; Ikka Grey-Eyes was with me, and Hearth Chief Zola named me.

("Why me…" is the engine's own arrival line. It is the same for both models.)

### A guilty commoner questioned

**gpt-5.6-terra**
> **Seko Cold-Swimmer:** I am here. I am here. What would you have of me?
> **You:** Did you do this?
> **Seko Cold-Swimmer:** O Luminous One, I did not do it; spare me for my two children, for a net catches more than the eel.

**gpt-6-luna**
> **Zola Tall-Grass:** I am here. You called me, Sky-Holder.  *(the speaker slip: this is Seko's line)*
> **Seko Cold-Swimmer:** I am here. I am here. What would you have of me?
> **You:** Did you do this?
> **Seko Cold-Swimmer:** O Luminous One, don't lay the whole weight on me; I kept the stores, and fear has made my mouth small.

## Spend

- Total actual spend: **$0.1956** ($0.1859 Terra, $0.0097 Luna). The cap was $2.00 and the guard's stop point was $1.80.
- Before the run, the dry-run worst-case estimate was $0.77.

## Recommendation

**Switch the live court voice to `gpt-6-luna`.**

- **Cost.** It costs about 1/19th as much per exchange ($0.00044 against $0.00845).
- **Speed.** It is faster (p90 6.1 s against 9.2 s).
- **Validity.** It matched Terra on structured output (22/22 valid and accepted).
- **Faithfulness and style.** It made fewer errors that affect play:
  - no misread orders, where Terra had two;
  - no narration against the engine, where Terra had one;
  - fewer stock sayings (3 against 5).
- **Where it is weaker.** It produced one wrong-speaker line, and a line or two of looser instruction following.
- **Voice.** Terra's voice work is a little richer: Diru's reflections are more distinct. That same richness is where its invented maxims come from.

This is a small sample: 22 exchanges per model, one seed and one era (the prehistoric band). Before switching, a short multi-year playtest on Luna would confirm the speaker-slip rate.

### What switching would involve (not done)

- `scripts/pronouncement_interpreter.gd`: change `DEFAULT_API_MODEL` to `"gpt-6-luna"`. This also changes:
  - the default in the AI Connection panel (`scripts/hud/ai_connection_panel.gd`);
  - the pronouncement interpreter, which has **not** been tested here. It uses a 2800-token cap and its own prompt, and would need its own check.
- `tools/launch_game.ps1` line 71 forces `LEVIATHAN_AI_MODEL` to `gpt-5.6-terra` when the user variable is unset. This must change too, or be overridden by setting the user environment variable `LEVIATHAN_AI_MODEL=gpt-6-luna`, which switches the Windows game with no code change.
- On the Mac, a Keychain connection saved with a model name keeps that model until it is re-saved.
- Tests that assert the Terra id need updating: `tests/test_directive_system.gd:112-114` and `tests/test_visual_ui_presentation.gd:123`.
- Separately from the model choice, `court_commands.gd` should ignore `target_ref: "me"` or "the god" when it resolves an order's target. This is the Terra temple failure.

## Reproducing

```
# dry run: no network, prints each call's worst-case estimate
MODEL_AB_DRY=1 <godot> --headless --path <worktree> res://tools/model_ab_probe.tscn -- --out=<dry.json>
# live run: spends money, guarded at $1.80
<godot> --headless --path <worktree> res://tools/model_ab_probe.tscn -- --out=<live.json>
python tools/model_ab_report.py <live.json> --transcripts
```

- The probe refuses to run unless `override.cfg` isolates user data (a `TomorrowFun*` directory).
- It reads the key from `LEVIATHAN_AI_API_KEY` or `OPENAI_API_KEY`, and only ever places it in the Authorization header.
- The run JSON is not committed.
