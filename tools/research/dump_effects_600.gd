extends SceneTree
## Headless dump of every live discovery's final effects, era and gate, for
## tools/research/rebalance_effects_600.py. Never launches the player scene.
##   <godot> --headless --path <worktree> -s res://tools/research/dump_effects_600.gd -- <output.json>
func _initialize()->void:
	call_deferred("run")

func run()->void:
	for name:String in ["GameState","CivilizationSystem","MilitaryCampaign"]:root.get_node(name).set_process(false)
	var args:=OS.get_cmdline_user_args()
	var output:=String(args[0]) if args.size()>0 else "user://effects_600_dump.json"
	var discovery:Node=root.get_node("DiscoverySystem")
	discovery.initialize()
	var catalog:Script=load("res://scripts/research_600_catalog.gd")
	var rows:Array=[]
	for entry:Dictionary in discovery.technology_catalog:
		var id:=String(entry.get("id",""))
		rows.append({"id":id,"line":String(entry.get("dynamic","")),"registry":catalog.has(id),
			"year":float(entry.get("design_year",discovery.discovery_era(id))),"era":discovery.discovery_era(id),
			"earliest_year":float(entry.get("earliest_year",0.0)),"effects":entry.get("effects",{}),
			"row_effects":(catalog.effect_row(id) as Dictionary).has("effects"),
			"requires_all":entry.get("requires_all",entry.get("requires",[]))})
	var file:=FileAccess.open(output,FileAccess.WRITE)
	file.store_string(JSON.stringify({"limits":_limits(),"rows":rows}))
	file.close()
	print("dumped %d entries to %s" % [rows.size(),output])
	quit(0)

func _limits()->Dictionary:
	var result:Dictionary={}
	var limits:Dictionary=(load("res://scripts/society_model.gd") as Script).get_script_constant_map().get("EFFECT_LIMITS",{})
	for key:Variant in limits:result[String(key)]=[(limits[key] as Vector2).x,(limits[key] as Vector2).y]
	return result
