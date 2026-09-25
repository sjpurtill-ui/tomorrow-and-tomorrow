extends SceneTree
## Headless snapshot of the LIVE research catalog for the Python surrogate
## (tools/sim). Never launches the player scene and never writes game data.
##   <godot> --headless --path <worktree> -s res://tools/sim/dump_catalog.gd -- <output.json>
## The surrogate reads data/research/*.json directly for every registry id; this
## snapshot only supplies what lives in GDScript catalogs (subcategory, signals,
## authored effects, authored routes, resource requirements, eras and gates of
## the ~686 entries outside the registry) plus the world's starting knowledge.

func _initialize()->void:
	call_deferred("run")

func run()->void:
	for name:String in ["GameState","CivilizationSystem","MilitaryCampaign"]:
		var node:=root.get_node_or_null(name)
		if node!=null:node.set_process(false)
	var args:=OS.get_cmdline_user_args()
	var output:=String(args[0]) if args.size()>0 else "user://sim_live_catalog.json"
	var Pathways:Script=load("res://scripts/knowledge_pathways.gd")
	var Opening:Script=load("res://scripts/opening_opportunities.gd")
	var discovery:Node=root.get_node("DiscoverySystem")
	discovery.initialize()
	var catalog:Script=load("res://scripts/research_600_catalog.gd")
	var rows:Array=[]
	for entry:Dictionary in discovery.technology_catalog:
		var id:=String(entry.get("id",""))
		var routes:Array=[]
		var definitions:Array=entry.get("learning_routes",[])
		if definitions.is_empty():
			routes.append({"id":"local","all":entry.get("requires",[]),"any":[]})
			var alternate:Dictionary=(Pathways.get_script_constant_map().get("ALTERNATIVES",{}) as Dictionary).get(id,{})
			if not alternate.is_empty():routes.append({"id":"experimental","all":alternate.get("requires",[]),"any":alternate.get("requires_any",[])})
		else:
			for definition:Dictionary in definitions:
				routes.append({"id":String(definition.get("id","")),"all":definition.get("requires_all",definition.get("requires",[])),"any":definition.get("requires_any",[])})
		rows.append({"id":id,"line":String(entry.get("dynamic","")),"subcategory":String(entry.get("subcategory","")),
			"registry":catalog.has(id),"signals":entry.get("signals",[]),"chance":float(entry.get("chance",0.0)),
			"era":discovery.discovery_era(id),"earliest_year":float(entry.get("earliest_year",0.0)),
			"design_year":float(entry.get("design_year",-1.0)),"effects":entry.get("effects",{}),
			"requires_all":entry.get("requires_all",entry.get("requires",[])),"requires_any":entry.get("requires_any",[]),
			"routes":routes,"resource_requirements":entry.get("resource_requirements",[]),
			"opening_gate":(Opening.get_script_constant_map().get("RULES",{}) as Dictionary).has(id),"conditions":entry.get("conditions",{}),"precedents":entry.get("precedents",[])})
	var starting:Array=[]
	for id:Variant in root.get_node("GameState").known_discoveries:starting.append(String(id))
	var subcategories:Dictionary={}
	for dynamic_id:Variant in root.get_node("GameState").research_subcategory_allocations:
		subcategories[String(dynamic_id)]=(root.get_node("GameState").research_subcategory_allocations[dynamic_id] as Dictionary).keys()
	var file:=FileAccess.open(output,FileAccess.WRITE)
	file.store_string(JSON.stringify({"schema":"sim_live_catalog/1","generated_unix":Time.get_unix_time_from_system(),
		"research_600_meta":catalog.meta(),"starting_known":starting,"subcategories":subcategories,"rows":rows}))
	file.close()
	print("SIM_DUMP %d entries -> %s" % [rows.size(),output])
	quit(0)
