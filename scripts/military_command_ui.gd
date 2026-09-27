extends Node
## Hosts the battle view over the map (the MilitaryCommandUI autoload).
##
## The old dark military command window that used to live here (direct
## training, production and army forms, prisoner policies, "hold this round")
## was removed: generals run battles and the player talks to them in the
## court. What remains is the layer that shows a battle while it is fought.

var layer:CanvasLayer
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


## Shows the battle being fought (or a recorded one, by its seed).
func _open_battle_graphics(_army_id:int=0,history_seed:int=-1)->void:
	if is_instance_valid(battle_graphics): return
	if MilitaryCampaign.active_engagement.is_empty() and MilitaryCampaign.battle_history.is_empty():
		_toggle()
		return
	battle_graphics=preload("res://scripts/battle_graphics_screen.gd").new()
	if battle_graphics is BattleGraphicsScreen: battle_graphics.history_seed=history_seed
	layer.add_child(battle_graphics)


## The old window's entry point: the war leader now answers in the court.
func _toggle()->void:
	var leader:Dictionary=preload("res://scripts/hud/paper_sheet.gd").war_leader()
	preload("res://scripts/hud/paper_sheet.gd").summon(leader.get("target",{}))


func _refresh()->void:
	pass
