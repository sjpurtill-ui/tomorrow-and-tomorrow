extends RefCounted
class_name DockContentBase
## Base for dock section content providers. A provider returns plain data
## dictionaries that DockPanel/DockBlocks render; it reads live game state on
## every call so the 0.75s live-report tick can rebuild the body cheaply.

const Tokens:=preload("res://scripts/hud/hud_tokens.gd")

var terrain:Node
var hud:Control

func _init(terrain_node:Node,hud_node:Control)->void:
	terrain=terrain_node
	hud=hud_node

func meta()->Dictionary:
	return {"eyebrow":"","title":"","subtabs":["","",""]}

func tab(_sub:int)->Dictionary:
	return {"kpis":[],"brief":{},"blocks":[]}

func jump(section:String,sub:int)->Callable:
	return func()->void: hud.section_requested.emit(section,sub)

## Maps the legacy {status,why,next} brief dicts onto the dock brief shape.
func adapt_brief(brief:Dictionary,tone:String,action_label:String,on_action:Variant=null)->Dictionary:
	var result:={
		"tone":tone,
		"title":String(brief.get("status","")).capitalize(),
		"why":String(brief.get("why",""))+"  "+String(brief.get("next","")),
	}
	if action_label!="":
		result["action_label"]=action_label
		if on_action is Callable: result["on_action"]=on_action
	return result

func signature()->Array:
	## Values hashed by the live-report tick; rebuild when they change.
	return []
