# Production clarity and valid equipment choices

Worktree /Users/seanpurtill/Documents/Codex/tt-production-clarity, branch
codex/production-clarity, base 75a1f32df223037eda11f5d2cc90889c0a3ca4ae.

Supply opens with active lines, state, stock, explicit finite/no-limit targets and
material-limited forecast. Detail shows stored/per-item/daily materials. Locked
products are omitted in both production selectors and retool lists. Existing
lines recheck research before consuming materials. New lines reject unusable
workforce, zero military crafting share and insufficient input for one item, with
specific reasons. Continuous remains explicit; default API target is now five.
Existing line targets and accumulated stock are untouched. “Improvised” becomes
“Simple levy weapons” in production and composition, with equipment/unit purpose.
Composition exposes all valid unit/equipment pairs instead of only the first
weapon for each unit and at most three new unit buttons.

Owned: persistent_production.gd, military_campaign.gd (default only), military
command UI, production lines panel, dock military provider, production tests.
No new population authority, no stock/save migration, no shared conflicts. This
is not a claim of comprehensive HOI4 parity or a fifty-unit roster.

Import retry clean after first native Godot importer crash (no GDScript errors).
24 production/quote tests passed, then 19 production cases passed after adding
composition regression; together 25 unique cases pass, including UI width,
research rejection, materials/worker rejection, material-limited output, finite
targets, save round-trip, conservation, and newly known spear choice for levies.
Logs /tmp/production-clarity-import-retry.log, /tmp/production-clarity-tests-final.log,
/tmp/production-clarity-composition-tests.log. Headless isolated data/Dummy audio.
