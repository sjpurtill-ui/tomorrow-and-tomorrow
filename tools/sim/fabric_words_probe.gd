extends Node
## Prints the built fabric's screen words (People view line, the headman's
## fact, the Buildings page lines, a great work's stated odds) for a town of
## 400 with timber framing, mudbrick and dry stone known and builders' craft
## 4, after ten years of reckonings. Headless; disposable state.
##   Godot --headless --path <wt> res://tools/sim/fabric_words_probe.tscn
const Fabric:=preload("res://scripts/built_fabric.gd")

func _ready()->void:
	WorldSimulation.clear()
	GameState.reset_for_new_world(8713)
	DiscoverySystem.reset_for_new_world()
	DiscoverySystem.initialize()
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	GameState.initialize_population_model()
	GameState.ensure_population_total(400)
	GameState.settlement_site_committed=true
	GameState.settlement_founded_day=0
	GameState.settlement_completed=["Hearth Circle","Lean-to Shelters","Storage Pits","Open Work Area","Gathering Yard"]
	GameState.city_form={"tier":2.0,"condition":1.0}
	GameState.housing_capacity=430
	GameState.elapsed_days=36500
	GameState.population_allocations.merge({"Construction":40,"Logistics":20,"Crafting":30,"Administration":12,"Knowledge":10,"Extraction":30},true)
	GameState.simulation_metrics["labor_efficiency"]=0.95
	for id in ["thatched_roofing","framed_construction","mould_made_mudbricks","dry_stone_walls","kiln_control","well_siting","shrine_wall_painting","megalith_raising"]:
		if id not in GameState.known_discoveries:GameState.known_discoveries.append(id)
	for item in ["Timber","Clay","Stone","Fiber Plants"]:GameState.resource_stockpiles[item]=3000.0
	Fabric.realm_data()
	GameState.fabric_realm["xp"]=4.0*Fabric.CRAFT_PER_LEVEL*400.0
	GameState.fabric_realm["decay_day"]=36500
	var f:=Fabric.data()
	for i in 36:
		GameState.elapsed_days+=100
		for item in ["Timber","Clay","Stone","Fiber Plants"]:GameState.resource_stockpiles[item]=float(GameState.resource_stockpiles[item])+400.0
		Fabric.reckon(f,100.0)
		f.day=GameState.elapsed_days
	var line:=Fabric.role_line(10.0)
	print("PEOPLE_NOW ",line.now)
	print("PEOPLE_TEN ",line.plus_ten)
	print("COURT ",Fabric.court_line())
	for l:Dictionary in Fabric.effect_lines():print("EFFECT ",l.label," | ",l.value," | ",l.words)
	for l:Dictionary in Fabric.plus_lines(10.0):print("PLUS ",l.label," | ",l.value," | ",l.words)
	var built:=Fabric.great_capability(GameState,{"Stone":400.0})
	print("GREAT ",Fabric.great_words(built,Fabric.great_payoff(GameState,true),{"collapse":0.17,"triumph":0.18,"flawed":0.12},"Ama"))
	var dock=preload("res://scripts/hud/content/dock_content_construction.gd").new(null,null)
	for block:Dictionary in dock._fabric_blocks():
		print("BLOCK ",block.get("heading","")," | ",block.get("note",""))
		if block.has("legend"):print("  LEGEND ",block.legend)
		for item:Dictionary in block.get("items",[]):print("  ITEM ",item.get("name",item.get("label",""))," | ",item.get("value",""))
	WorldSimulation.clear()
	get_tree().quit(0)
