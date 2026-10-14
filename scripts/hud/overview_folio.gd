extends "res://scripts/hud/settlement_overview.gd"
## HOME › OVERVIEW, compact: the six tiles under the tabs carry the headline
## figures (dock_content_settlement.gd _glance_tiles); this page is the rest,
## each fact one line (its mark, its name, its value at the right, a thin bar
## with the bands of the towns our scouts have seen), flowing into two or
## three columns as the page widens. The leader is one row with the controls
## that change the town's work beside them. No figure here repeats a tile.

func _layout() -> void:
	if spread: spread.vertical = false
	if grid: grid.columns = 3 if size.x >= 1050 else (2 if size.x >= 540 else 1)
