# Popup redesign audit — October 14, 2026

Scope: every reachable popup and its subpages. Presentation, information hierarchy,
navigation and readability only; simulation, availability rules, action callbacks
and saved state remain owned by their existing systems.

Baseline: `d179b5ee6f86e0a8ed3c4cbbb641e230905ef713`. Canonical game:
`C:/Users/sjpur/TomorrowandTomorrow`. Root integrates; workers use their own
`codex/popup-design-*` worktrees. No isolated preview is the player build.

## Review loop

On 2026-10-14 the user selected Modern Strategy and authorized its application to
every popup and subpage. See MODERN_STRATEGY.md for the palette, type and control
specification. Earlier layout improvements remain; beige styling is superseded.

Designer A implements a screen, designer B critiques its rendered result while
implementing another screen, A revises and critiques B, and B revisits the revision.
Each screen requires a rendered comparison, an independent critique and closure
of actionable findings. Shared helpers receive a separate independent review.

## Coverage ledger

| Family | Reachable views and nested surfaces | Status |
|---|---|---|
| Shared shell | Category tabs, detail/back, KPI strip, briefs, tables, modal fitting | Complete — Modern Strategy tokens, readable scrolling, independent contrast/visual review |
| Production | Workshops, Goods, Arms, picker, queue, line inspector | Complete — A/B critique, revision and recheck; 39 tests, desktop/narrow captures |
| Research | Effort, tree, known discoveries, question picker, discovery announcement | Complete — B/A critique and recheck; 20 focused tests plus 11 dock tests |
| Home | Overview, People, Culture, Council, person/office, labor and impact | Awaiting design |
| Health and population | Lives, sickness/disasters, population, every death | Awaiting design |
| Food and materials | Food/water/fire, resource details, priorities, deliveries | Complete — A/B critique, revision and recheck; healthy/shortage/source captures, live updates and callbacks tested |
| Wealth and trade | Accounts, holdings, obligations, partners and actions | Awaiting design |
| Buildings | Town, civic works, infrastructure, landmarks, queue, material bills, history | Awaiting design |
| World | Peoples, expeditions, history, dossiers, scout findings/journey, planner, rumors | Main pages complete — C/root critique and recheck; nested reports in progress |
| Standing and spies | Own/foreign assessments, intelligence details, warnings and actions | Complete — C/root visual review, 43 Standing/Covert cases |
| War and command | Army/fronts/leaders, border/fort, hierarchy orders/zones/organization, later services | Army/fronts/leaders and Orders complete; nested command final check pending |
| Battle and services | Live/replay/report, siege, occupation, recovery, navy/air/dock and transport | Complete — C/root critique, service navigation revision and recheck; 40 service captures, battle/siege/aftermath probes |
| Court | Court roster, audiences/envoys, foreign exchange/pacts, history, receipt, office and judgment UI | Awaiting design |
| Direction and figures | Course/character, people browser, biography/event history | Awaiting design |
| Collections | Artifact status filters, sets/rumors, selected artifact, exchange/gift/sell/swap | Awaiting design |
| Great works | Ours/foreign, work detail, construction, enshrine picker, dedication | Awaiting design |
| Opening and travel | First fire/purpose/naming, founding guide, caravan/convoy/arrival, rename | First fire complete after C review; pinned confirmation and scroll on narrow. Travel pending |
| Settings | Pause/save/load, display/audio/navigation, AI, new world, confirmations | In progress — root |
| Records and small popups | Chronicle pages, notices, all orders, hover, map help/survey/contact/battle/border notes | Awaiting design |

The baseline has seven categories and 27 declared tab destinations. War routes to
the current roster/war board, not the compatibility provider's old forms. Scout
dispatch routes to Expeditions; diplomat dispatch routes to the court. Research
purchase, technology operations, clothing and scout-target legacy panels have no
current production caller; community-network opening has no current caller or
hotkey. Dormant code is excluded unless a reachable runtime route is demonstrated.

## Navigation decisions

- Merge Production's overview and civilian work into Daily work. Keep Workshop
  orders as a distinct task. Preserve old numeric links through presentation aliases.
- Research's effort, future question selection and accumulated knowledge have
  distinct tasks; retain the three direct destinations unless rendering proves a
  simpler alternative preserves long-history browsing.
- Fleet and Air preparation contained only links. Put their existing command
  and production actions on Forces; keep old page IDs as navigation aliases.
- World relationships belong inside each people dossier. Retain detailed
  assessments as an inline disclosure instead of a second table of people.
- Replace generic modal shrinking/automatic child paging with readable overflow;
  a window size must not invent semantic subpages or reopen a collapsed section.

## Acceptance

Use the private-desktop GPU probe with Dummy audio and isolated userdata. Check
normal and narrow canvases, light/dark where shared colors change, empty/populated
states, long names and histories, keyboard focus, action reachability, scrolling,
live refresh stability and the existing relevant functional tests. Generated
captures stay in artifacts. A source audit alone is not visual acceptance.

## Modern Strategy accepted checkpoints

- Shared foundation: `ce854947`; Production: `5d4867b2` (worker `a68023a0`).
- Army/fronts/leaders: C rejected the first color-only pass as too dense. Revision
  adds raised sections, a 32 px army count, portrait leader cards with labelled
  ratings, and an inline cost comparison with current warnings left visible.
  C caught wide-panel overflow; wrapping stance controls and wider bounded panes
  resolve it. All 27 War/unified-navigation cases pass; twelve private GPU
  captures cover three views, both appearances and 1024/1600 widths.
- First fire: C required the confirmation to stay visible while extra choices
  scroll. The final narrow capture has a pinned primary action and naming fits
  its contents. Purpose selection, naming callbacks and game rules are unchanged.
- Folio surface now uses the palette directly in both modes; removed the old
  beige override and paper-grain shader so Daylight remains cool neutral.
- Services: C requested removal of empty preparation pages and larger native
  tabs. Direct actions on Forces and 40 px command tabs passed the revised
  40-capture probe. Eight roster cases pass; earlier 83 battle/command cases
  pass. Siege opens/reopens through all four wall stages at 800/1280 widths;
  recovery retains real prepare/commit/cancel behavior. Occupation's minimum
  scroll height was reduced after an 800x600 overflow; final two-size probe
  and C visual recheck pass. These changes do not alter orders or calculations.
