# Modern Strategy

Selected by the user on 2026-10-14 for every reachable popup and subpage.
This supersedes earlier beige-paper UI styling. World art and spoken quotations
remain illustrative and expressive; interface hierarchy uses the bundled Barlow.

## Tokens

| Role | Night | Daylight counterpart |
|---|---|---|
| Main surface | #111E28 | #F2F5F5 |
| Raised surface | #1B303A | #FFFFFF |
| Primary text | #F4EEE0 | #142B34 |
| Secondary text | #B7C5C7 | #4E626A |
| Primary command | #F38665 | #B7442C |
| Command text | #14232B | #FFF9EF |

Night is the selected default. An appearance-version marker migrates older
machine-local UI settings once; later explicit Daylight selections are respected.
No world-save or simulation fields change.

## Composition and controls

- Lead with the current situation, one main decision, and two or three useful
  readings. Put detailed evidence below or in an explicit inline disclosure.
- Use actual existing illustrations and portraits, sized to support the decision.
- Sans window titles 28–32 px, section titles 18–22 px, body 16 px, supporting text 14 px.
  Keep concise 12 px kickers exceptional; do not shrink whole windows to fit.
- Primary controls use solid coral and dark text in Night. Secondary actions use
  quiet outlines. Navigation and filters use selected surfaces and a coral mark.
- Primary targets are 44–48 px tall; secondary targets at least 40 px. Radius 4 px
  for controls, 8 px for surfaces; 8 px spacing base and 8–16 px group gaps.
- Bound reading width to 1120 px. Keep labels, values and actions together;
  never stretch a fact across the entire window or equalize independent groups
  into rows with large empty space. Use additional width for useful comparisons.
- Default pages summarize the current situation and a selected entity. Show
  three recent records; provide explicit full-history search with six per page.
  Catalogues use bounded choices and a selected detail, not an endless card wall.
- Keyboard focus stays visible. Every text/ground pair must remain legible in all
  active, hover, pressed, disabled and selected states. Color never carries a
  status by itself.
- Tabs separate tasks. Status/category filters stay within a task. Preserve old
  numeric deep links with presentation aliases when combining destinations.

Use HudTokens and apply_button_style rather than local copies of the palette.
Compatibility names such as PAPER and GOLD remain stable for existing callers.
Keep all calculations, availability rules, command payloads and callbacks intact.

## Review

Each screen owner renders, receives another agent's critique while moving to a
different screen, revises the first, and receives a recheck. Check dense and empty
states, nested pages, narrow windows and both appearances. A token conversion alone
does not constitute completion of a screen's information-design audit.
