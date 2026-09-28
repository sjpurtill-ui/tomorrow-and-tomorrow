extends Node
## Opens the battle view over the map (the MilitaryCommandUI autoload).
##
## The old dark military command window that used to live here (direct
## training, production and army forms, prisoner policies, "hold this round")
## was removed: generals run battles and the player talks to them in the
## court. The stick-figure replay is gone too: every way into a battle (the
## report card, the court, the Chronicle, war planning, the siege screen and
## the map's battle marks) now opens the battle panel (hud/battle_panel.gd)
## through BattleView.

const View:=preload("res://scripts/hud/battle_view.gd")

var layer:CanvasLayer
## The battle panel now open, if any (set by BattleView.open).
var battle_graphics:Control
## Kept so older callers that ask "is the military window open?" get "no".
var modal:Control


func _ready()->void:
	layer=CanvasLayer.new()
	layer.layer=2
	add_child(layer)
	modal=Control.new()
	modal.name="RetiredMilitaryCommand"
	modal.visible=false
	modal.mouse_filter=Control.MOUSE_FILTER_IGNORE
	layer.add_child(modal)


## Shows a battle: the one with this seed (live or recorded), else the one
## being fought by this army, else any being fought, else the last one fought.
func _open_battle_graphics(army_id:int=0,history_seed:int=-1)->void:
	var found:Dictionary=View.find(history_seed) if history_seed>=0 else View.pick(army_id)
	if found.is_empty():
		_toggle()
		return
	View.open_found(found)


## Shows the battle with this engagement id (the map's battle marks call this).
func open_engagement(engagement_id:String)->void:
	var found:Dictionary=View.find(engagement_id)
	if found.is_empty():
		_open_battle_graphics()
		return
	View.open_found(found)


## Whether the battle panel is open now.
func battle_open()->bool:
	return is_instance_valid(battle_graphics)


## The old window's entry point: the war leader now answers in the court.
func _toggle()->void:
	var leader:Dictionary=preload("res://scripts/hud/paper_sheet.gd").war_leader()
	preload("res://scripts/hud/paper_sheet.gd").summon(leader.get("target",{}))


func _refresh()->void:
	pass
