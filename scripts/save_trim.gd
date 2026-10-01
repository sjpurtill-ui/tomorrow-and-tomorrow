extends RefCounted
## Lists a save carries that grew past what the screens and rules read, made
## small when the world loads (save_system.gd): every people's own records and
## each of its towns'. The same trimming happens day by day as records age
## (economy_system.gd slim_history_entry), so a new save never needs it.

static func trim_world()->void:
	_trim_owner(GameState)
	for id:String in WorldSimulation.actors:
		var systems:Dictionary=WorldSimulation.actors[id].systems
		_trim_owner(systems.GameState)

static func _trim_owner(state:Object)->void:
	var Economy:=preload("res://scripts/economy_system.gd")
	Economy.slim_history(state.economy_history)
	_compact_loads(state.resource_deposits)
	for city:Variant in state.player_settlements:
		if not city is Dictionary:continue
		var local:Variant=(city as Dictionary).get("local_resources",{})
		if not local is Dictionary:continue
		if (local as Dictionary).get("economy_history") is Array:Economy.slim_history(local.economy_history)
		if (local as Dictionary).get("resource_deposits") is Array:_compact_loads(local.resource_deposits)

## Loads on the road in the compact form (resource_system.gd normalize_shipments).
static func _compact_loads(deposits:Array)->void:
	var Resources:=preload("res://scripts/resource_system.gd")
	for deposit:Variant in deposits:
		if not deposit is Dictionary:continue
		var loads:Array=(deposit as Dictionary).get("shipments",[])
		if not loads.is_empty() and (loads[0] is Dictionary or not (deposit as Dictionary).has("in_transit")):
			Resources.normalize_shipments(deposit)
