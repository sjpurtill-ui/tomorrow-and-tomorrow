extends "res://scripts/hud/content/dock_content_base.gd"
## The border panel opened from the War screen's Border card: each stretch's
## watch, our forts and what they cost, and the war leader's sites
## (border_blocks.gd).

const BorderBlocks:=preload("res://scripts/hud/content/border_blocks.gd")
const Forts:=preload("res://scripts/fort_border.gd")

func meta()->Dictionary:
	return {"eyebrow":"THE BORDER","title":"Forts and the watch","subtabs":["BORDER"]}

func tab(_sub:int)->Dictionary:
	return {"kpis":[],"blocks":BorderBlocks.blocks(hud)}

func signature()->Array:
	return [var_to_str(Forts.forts()),Forts.border_share(),floori(GameState.elapsed_days),GameState.population_allocations.get("Defense",0)]
