# Military glyph layout preservation

Base 98384e3e63d2c0fe5727a87827225adaa7b7fb98; branch codex/military-glyph-layout.

The update pass overwrote every glyph component's X/Z, erasing authored wheel/head/barrel offsets. Cache each authored position after icon configuration; translate the whole symbol from those fixed positions for readiness. No accumulation, new render nodes, troop data, combat, selection, or save changes.

Runtime probe passes with six icon families checked for relative offsets, repeated-update stability, and low-readiness coherence. Map-presentation unit suite passes. Inspected artifacts/military-glyphs.png using new self-terminating tools/military_glyph_probe.gd. Current icon art and text density still warrant further polish; this fixes layout, not a full redesign. Existing full-scene test shutdown resource warnings persist.

Shared scope: _configure_warfare_role_glyph and _apply_warfare_formation_view, plus runtime tests. No player game launched.
