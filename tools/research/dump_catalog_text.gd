extends SceneTree
## Headless dump of every live discovery's player-facing text and production
## links (name, observation, contracts, production_items, era), for the
## research cleanup audits in tools/research/. Never launches the player scene.
##   <godot> --headless --path <worktree> -s res://tools/research/dump_catalog_text.gd -- <output.json>
func _initialize()->void:
	call_deferred("run")

func run()->void:
	for name:String in ["GameState","CivilizationSystem","MilitaryCampaign"]:root.get_node(name).set_process(false)
	var args:=OS.get_cmdline_user_args()
	var output:=String(args[0]) if args.size()>0 else "user://catalog_text_dump.json"
	var discovery:Node=root.get_node("DiscoverySystem")
	discovery.initialize()
	var rows:Array=[]
	for entry:Dictionary in discovery.technology_catalog:
		var row:Dictionary={"era":discovery.discovery_era(String(entry.get("id","")))}
		for key:Variant in entry:
			var value:Variant=entry[key]
			if value is String or value is Array or value is float or value is int or value is bool or String(key)=="effects":row[String(key)]=value
		rows.append(row)
	var file:=FileAccess.open(output,FileAccess.WRITE)
	file.store_string(JSON.stringify({"rows":rows}))
	file.close()
	print("dumped %d entries to %s" % [rows.size(),output])
	quit(0)
