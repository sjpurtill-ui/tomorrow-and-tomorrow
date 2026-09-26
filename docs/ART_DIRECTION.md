# Art Direction

Audit of main `e3537ceb` (2026-09-25). Eleven GPU captures (1600x900, plus the 1920x1080 envoy probe) show the founding naming scene, day 30 at 200 m, the valley and regional views, year 5 map, Court, The People, Known World, Chronicle, research atlas, and the envoy scene in dark and light. The top-bar hover card could not be captured headlessly because it closes when the pointer is not on its anchor. It is judged from `scripts/hud/hover_card.gd`. The captures are local only and not committed.

**Verdict.** The screens with a strong idea already look good: Known World with its hide map, the Chronicle, the People banner, and the envoy stage. The game as a whole looks cheap because of three things. First, the map at every zoom is neon green noise. Second, five typefaces and about 20 font sizes compete on one screen. Third, three visual languages sit side by side: a dark teal rail, cream paper panels, and dark-glass modals. Fix the map colour, the type system, and the chrome, and most of "not elegant" goes away.

## 1. Visual identity

**An illuminated field chronicle.** The player is a god reading the story of a people, written by the people in their own hand. The world below is a painted landscape with low, warm light, never a satellite photo. The desaturated earth greens, ochres and slate waters of an old hand-coloured map carry it. Everything the player reads is ink on warm hide or parchment: iron-gall brown-black text, one oxblood and one verdigris accent, gold only for what is sacred or chosen. Titles are carved, in Cinzel, used rarely and large. Voices (quotes, tales, the envoy's words) are set in a book serif. Numbers and controls use one quiet humanist sans. Scenes (the fire circle, the court ring, the envoy's arrival) are the only places with dramatic light: dusk, firelight, long shadows. The UI frames the world like a book margin, never a dashboard, and it thins as the era advances, from hide to vellum, then paper, then printed plate.

## 2. Design tokens

Implement as **one** `res://ui/theme/chronicle_theme.tres`, built by `scripts/hud/hud_tokens.gd` (keep the class name `HudTokens`; extend it rather than fork it), plus a `project.godot` `gui/theme/custom` pointer so the engine fallback font disappears. `HudTokens` stays the single source. Every `Color("…")` literal in `scripts/hud` migrates to a token over time. Today there are about 1,320 hex literals and 740 token references.

### Palette (light is the default, "hide")

| Token | Light | Dark ("night fire") | Use |
|---|---|---|---|
| `PAPER` | `#EFE6D4` | `#14110D` | Dock and panel ground |
| `PAPER_RAISED` | `#F6EFE1` | `#1C1813` | Cards and tiles |
| `PAPER_SUNK` | `#E3D7C0` | `#0E0C09` | Rows, fields, tracks |
| `RULE` | `#B7A383` | `#3A3226` | 1 px hairlines and panel borders |
| `RULE_STRONG` | `#8C7757` | `#56493A` | Focused and selected outlines |
| `INK` | `#1F1A14` | `#F1E7D2` | Titles and values |
| `INK_BODY` | `#3A3128` | `#D9CEB8` | Body text |
| `INK_MUTED` | `#6B5E4E` | `#A0937E` | Kickers and captions (must pass 4.5:1 on `PAPER`) |
| `GOLD` | `#9A6B1F` | `#D4AE5C` | Sacred, selected, primary action. Nothing else. |
| `OXBLOOD` | `#8E3B2E` | `#D07A66` | Danger, dread, loss |
| `VERDIGRIS` | `#3F6F63` | `#7FAEA2` | Good, water, knowledge |
| `OCHRE` | `#A8782A` | `#D9B26A` | Warning |
| `SCRIM` | `#1F1A14` at 55% | `#000000` at 65% | Behind modals: the map dims, and nothing shows through a panel |

Rules:
- **The rail uses `PAPER`, not teal `#172c32`.** One chrome language.
- Semantic colours tint only borders, icons and 8% washes, never large fills. The envoy answer cards (green, blue and red panels) become paper cards with a 3 px coloured top rule.
- **Map palette** for `local_terrain.gd` and the ground shaders. Grass is `#6E7F3E` to `#8A8A4A`, never above 45% saturation. Forest canopy is `#3E4A2C`. Dry ground is `#A89468`. Water is shallow `#5E7F7A` into deep `#2F4A52`. Fog of war is warm `#D9CDB5` at 85% with a hand-drawn edge, not black.

### Type

Three faces, all bundled. There are no `SystemFont` lookups: Georgia is missing on Linux and renders differently on the Mac clone.

| Role | Face | Sizes (px at 1920x1080) |
|---|---|---|
| Display (screen titles, scene names, stage-change title cards) | Cinzel Regular (bundled) | 40 / 28 |
| Voice (tales, quotes, envoy speech, aim titles) | **EB Garamond** or **Cormorant Garamond** (OFL; add under `assets/fonts/serif/`; roman + italic) | 22 / 18 |
| UI (values, labels, buttons, body) | Barlow (bundled). Use Medium for UI and SemiBold for values. Add Barlow Regular. | 20 value / 16 body / 14 small / 12 kicker |

- Kickers are 12 px Barlow SemiBold in caps at +0.12 em tracking, in `INK_MUTED`. **Only kickers are all caps.** No all-caps screen titles, buttons or place names.
- Minimum size is **12 px**. Today 9, 10 and 11 px make up about 190 overrides; they are the main cause of the "developer UI" feel.
- Line height is 1.35 for body and 1.2 for display.

### Spacing, shape, depth, motion

- Spacing uses a 4 px base: `4 8 12 16 24 32 48`. Panel padding is 24, card padding 16, row padding 12 x 8. Gaps between sections are 32, with a kicker and a hairline above each.
- Radii are `2` for controls and chips, `4` for cards and panels, and `0` for scene frames. There are no pill buttons.
- Borders: 1 px `RULE`. Selection is 1 px `GOLD` plus a 2 px gold left or top tab. Never draw a 2 px outline all round.
- Shadows: one elevation for floating panels only, `0 6 18` at 18% (light) or 45% (dark). Cards inside panels get no shadow.
- Motion: `FAST 120 ms` (hover and press), `BASE 200 ms` (dock slide and tab change), `SLOW 360 ms` (modal fade-in with 8 px rise), `SCENE 900 ms` (stage change and discovery reveal). Easing is `TRANS_CUBIC` `EASE_OUT` on entry and `EASE_IN` on exit. Respect a `reduce_motion` preference by capping every duration at 120 ms.

Token script sketch (add to `hud_tokens.gd`):

```gdscript
const SPACE:=[0,4,8,12,16,24,32,48]
const RADIUS_CONTROL:=2; const RADIUS_CARD:=4
const FONT_DISPLAY:=preload("res://assets/fonts/cinzel/Cinzel.ttf")
const FONT_UI:=preload("res://assets/fonts/battle/Barlow-Medium.ttf")
# FONT_VOICE / FONT_VOICE_ITALIC: bundled Garamond, replaces every SystemFont
const TYPE:={"display":[FONT_DISPLAY,40],"title":[FONT_DISPLAY,28],"voice":[null,22],
	"voice_small":[null,18],"value":[FONT_UI,20],"body":[FONT_UI,16],"small":[FONT_UI,14],"kicker":[FONT_UI,12]}
const MOTION:={"fast":0.12,"base":0.20,"slow":0.36,"scene":0.90}
static func text(label:Control,role:String,color:Color=INK_BODY)->void: ...  # the only way to size text
```

## 3. Top 10 visual problems (ranked by impact)

**1. The map is neon green noise at every zoom (L).**
- **Evidence:** In `a01-day30-200m`, `a04-year5-map`, `a02-valley` and `a03-regional`, 70–90% of the frame is saturated `#3A8A1E`-like green with a uniform blob canopy. There is no light direction, no ground variety and no readable landform. The regional view is soft green blotches with streaky coast banding.
- **Fix:** Grade terrain and canopy to the map palette. Add a warm key light low in the sky with ambient occlusion under canopy. Break up ground with dry-grass, bare-earth and path tints near the hearth. Add a mild distance haze toward `PAPER` at valley and regional heights. Draw hillshade on the regional macro raster so land has relief. The coast banding needs its own ticket; note it.
- **Files:** `scripts/local_terrain.gd` (environment and materials), `scripts/shaders/resource_ground.gdshader`, `scripts/coastal_water.gdshader`, vegetation material.

**2. There are five typefaces and about 20 sizes (M).**
- **Evidence:** One screen mixes the engine fallback sans, Barlow, Cinzel and SystemFont Georgia/Noto Serif. The Court title is fallback bold, the Known World has a Cinzel button, Georgia italics and Barlow numerals, and the research title is all-caps sans. There are about 190 overrides at 9–11 px.
- **Fix:** Build the token type scale above. Set a project-wide theme default font (Barlow). Bundle one Garamond and replace every `SystemFont`. Route all `font_size` overrides through `HudTokens.text()`.
- **Files:** `hud_tokens.gd`, `project.godot`, `chronicle_card.gd`, `chronicle_feed.gd`, `dock_blocks.gd`, `dock_panel.gd`, `artifact_gallery.gd`, then a sweep of `scripts/hud/**`.

**3. There are three chrome languages (M).**
- **Evidence:**
  - The rail is dark teal while the top bar and docks are cream paper (all map captures).
  - The Court has a dark-glass header over a paper body.
  - The research atlas is a translucent cream sheet with the Chronicle toast and top bar ghosting through (`a09`).
  - The envoy uses a dark or grey title bar.
- **Fix:**
  - All chrome is `PAPER` with a `RULE` border.
  - Modals are opaque, over a `SCRIM`.
  - Scene headers (Court, envoy) sit on the stage art itself with a paper plate, not a grey bar.
- **Files:** `command_rail_hud.gd` (`_approved_rail_style`), `audience_modal.gd`, `research_atlas.gd`, `knowledge_atlas.gd`, `dock_panel.gd`.

**4. The research atlas reads as a developer tool (M).**
- **Evidence:** In `a09`:
  - An all-caps title, "RESEARCH · PEOPLE & IDEAS".
  - A filter bar of dropdowns and a search field.
  - Truncated cards: "~0.5 researchers · 63% eviden…", "People & hom…".
  - Initials instead of a portrait ("HP").
  - Default Godot dropdown arrows and a scroll gutter.
- **Fix:**
  - Lead with the painted card art at full width and the subject name in Voice.
  - Replace the staffing numbers with the era sentence ("Hena and a few hands, most days").
  - Move filters into a quiet kicker row.
  - Use the leader's painted portrait (`person_portrait.gd`).
  - Never truncate a card; wrap it.
- **Files:** `research_atlas.gd`, `research_card_art.gd`, `research_visuals.gd`, `era_words.gd`.

**5. Map overlays are drawn like debug gizmos (S/M).**
- **Evidence:**
  - At 200 m and valley height, two neon yellow straight lines run from the hearth off-screen: the scout routes (`a01`, `a02`, `a03`).
  - In the valley view, a heavy beige 3D boundary ring.
  - The four-point sparkle stars in `a04` read like editor gizmos.
  - The regional hint strip "RECOGNIZED RESOURCES SHOWN • TWO-FINGER SLIDE TO PAN" is dev copy.
- **Fix:**
  - Scout routes become dashed ink footpaths that follow the ground, with small footprint ticks and a fade toward unknown.
  - Territory becomes a soft painted wash with an ink hairline edge.
  - The sparkle becomes a small gold glyph from `resource_icons.gd`.
  - Remove the control hint, or show it once in the first minute in era words.
- **Files:** `scout_route_overlay.gd`, `service_world_overlay.gd`, `local_terrain.gd`, `resource_icons.gd`.

**6. The bottom toolbar and the HELP pill are unfinished (S).**
- **Evidence:**
  - "FIRST SETTLEMENT" in 20 px caps next to "FOUND NEW SETTLEMENT" in 11 px caps, then "Close by" and "The valley" in 20 px sentence case.
  - An "N ←" chip.
  - The HELP pill is clipped under the rail ("ELP • ?") in every map capture.
- **Fix:**
  - One 40 px paper strip holding the place name in Voice, the actions as quiet text buttons with icons, and a compass glyph in place of "N ←".
  - Position the HELP pill at `RAIL_WIDTH + 16`.
- **Files:** `command_rail_hud.gd`, `local_terrain.gd` (toolbar build and help pill).

**7. The same portrait appears several times (M).**
- **Evidence:**
  - In `a06` People, "Faces at the fire" shows one painted portrait for Bekk, Tilla, Mira and Tuk.
  - The Court shows Hena twice.
  - The envoy "Pell" is a woman laying mats with a 50 px blank cream band above the image (`a10`).
- **Fix:**
  - Deterministic portrait variety per person from the existing painted set: crop or flip, a tint by age, and never the same image twice on one screen.
  - Fit images to fill the frame.
  - Prefer poses that match the role; an envoy should be standing or offering.
- **Files:** `person_portrait.gd`, `people_screen.gd`, `court_roster.gd`, `audience_modal.gd`.

**8. Court and scene stages are flat vector clip-art next to painted portraits (L).**
- **Evidence:** In `a05` Court and `a10`/`a11` envoy, the backdrop is flat triangles, poles and logs in one tan tone, with framed painted cards floating on it. Three styles meet on one screen: vector, illustrated portraits, and the photographic offer object on white.
- **Fix:**
  - Short term: paint the stage procedurally with depth and light: a firelight radial glow, a vignette, a warm ground gradient, silhouetted figures at the ring instead of framed cards, and sky by time of day.
  - Put the offered object on a hide cloth, not white.
  - Long term: painted backdrops per era (section 5).
- **Files:** `court_backdrop.gd`, `audience_modal.gd`, `fire_circle_opening.gd`.

**9. Hierarchy is flat and text is truncated (M).**
- **Evidence:**
  - Court columns end in "Only foreign envoys come unbidd…", "Your envoys carry your brief to…" and "Offline voice — AI is swi…".
  - An orphan "ASK ▾" button wraps to a second row.
  - The top-bar values ("120 souls", "32 days") are the same weight as their labels' neighbours.
  - The toast body is clipped with "…".
- **Fix:**
  - One primary reading per screen: the title, then one hero sentence, then the content.
  - Wrap and never ellipsize prose.
  - Put the AI and voice status in the settings cog.
  - Top-bar values use `value` 20 SemiBold `INK`, kickers use `kicker`, and sublines use `small` `INK_MUTED`.
- **Files:** `audience_modal.gd`, `court_roster.gd`, `command_rail_hud.gd`, `chronicle_card.gd`.

**10. There is almost no motion (S/M).**
- **Evidence:** Only five files create tweens. The dock slides in 0.16 s, `dock_panel` fades 0.1 s, and modals, toasts, tab changes and stage changes pop in with no transition.
- **Fix:** Use the motion tokens:
  - Modal: fade the scrim and give the card a 360 ms rise.
  - Toast: 200 ms slide from the right, with the gold kicker revealed 120 ms later.
  - Tab change: 200 ms cross-fade.
  - Hover card: 120 ms fade plus 4 px drop. It opens after 0.25 s and currently has no transition.
  - The Court fire flickers, via a shader on the fire glyph.
- **Files:** `hud_tokens.gd` (MOTION), `audience_modal.gd`, `chronicle_card.gd`, `hover_card.gd`, `dock_panel.gd`.

**Also noted**
- The People banner renders "FIRST SETTLEMENT" in caps inside a sentence; this is a data-case bug.
- "Year 6 · Day 2" and the tallies are ledger words in a prehistoric era; route them through `era_words.gd`.
- The founding scene moon is drawn as an eclipse disc.

## 4. Hero moments

1. **First light over the camp (the founding).** The camera starts at dusk over the valley in the map palette with haze. The naming scene fades to night, and when the name is given the sky warms over about 3 s to dawn. The first smoke rises and the camera settles to 200 m with the HUD fading in over 900 ms. The title card "Birchhollow · Year 1" appears in Cinzel 40 on a torn-hide plate. This is the game's first impression; today it cuts straight to green noise.
2. **The Court at a stage change** (the elders' ring becoming a hall, and so on). The old backdrop holds and the chronicle voice speaks one line in Garamond italic. The backdrop cross-dissolves over 1.5 s to the new stage while the court members' silhouettes walk to their new places. A gold kicker names the new court. Reuse `court_backdrop.gd` and add a transition state.
3. **A discovery card.** The painted discovery art rises from a darkened scrim and wipes in left to right like ink drying, over 900 ms. The subject name appears in Cinzel, the one-sentence meaning in Garamond, and "Known since Year 5" as a kicker. A hairline gold rule draws under the title. This replaces the current utilitarian popup (`discovery_popup.gd`) and is the payoff moment of the research loop.

## 5. Painted art the user would need to generate

Keep the style consistent with the existing painted portraits: warm naturalistic gouache, visible brushwork, soft edges, no photorealism.

- **Court stage backdrops (one per era, 2560x1080, empty centre for figures):** "Painterly gouache wide scene, [elders' ring of standing stones around a central fire at dusk / timber longhall interior with hearth / stone council hall with banners], warm firelight, long shadows, empty foreground ground plane, no people, muted earth palette, soft vignette."
- **Envoy arrival backdrop (2560x1080):** "Painterly gouache, a camp's edge at the hide palisade, late-afternoon light, a path leading in from distant hills, empty centre, muted ochre and slate palette."
- **Hide and parchment surface texture (tileable, 1024²):** "Seamless tileable texture of worn tanned hide, subtle fibres and stains, very low contrast, warm cream."
- **Portrait variety:** about 12 more early-era portraits (elders, children, envoys standing or offering) in the existing style, to end the repeats in problem 7.
