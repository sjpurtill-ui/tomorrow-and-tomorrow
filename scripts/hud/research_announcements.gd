extends RefCounted
## Completed discoveries are read in Research and the Chronicle. Keep this
## daily-loop entry point compatible with old saves without opening a popup.
const MODES=["milestones","all","quiet"]

static func important(_event:Dictionary,_mode:String,_first_batch:bool=false)->bool:
	return false

static func announce(_terrain_node:Node,_hud_node:Node,_events:Array[Dictionary])->CanvasLayer:
	return null
