extends Node
## FUN AUDIT quick probe (under two minutes, one process): boots the real game
## for one seed, founds where the people stand, lets a few weeks pass, then
## measures what the two bars show (UiMeasure.bars), which card layers exist,
## and the founding ground. Prints one JSON line.
##   <godot> --headless --path <worktree> res://tests/fun_audit/bars_probe.tscn -- --seed=424242 --days=30
## Requires the worktree override.cfg (isolated userdata). Never saves.
const UiMeasure:=preload("res://tests/fun_audit/ui_measure.gd")

func _arg(n:String,f:String)->String:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--%s="%n):return a.substr(n.length()+3)
	return f

func _ready()->void:
	if not OS.get_user_data_dir().ends_with("Tests"):
		push_error("needs isolated userdata");get_tree().quit(2);return
	var seed_value:=int(_arg("seed","424242"))
	GameState.reset_for_new_world(seed_value)
	DiscoverySystem.reset_for_new_world();ResourceSystem.reset_for_new_world();FoodSystem.reset_for_new_world()
	CivilizationSystem.reset_for_new_world();MilitaryCampaign.reset_for_new_world()
	GameState.civic_api_enabled=false
	var terrain:Node=load("res://local_terrain.tscn").instantiate();add_child(terrain)
	await get_tree().process_frame;await get_tree().process_frame
	PeopleDirection.choose("makers")
	if is_instance_valid(PeopleDirection.panel):PeopleDirection.panel.queue_free()
	terrain._start_settlement_here()
	if is_instance_valid(terrain.settlement_naming_panel):terrain.settlement_naming_panel.queue_free()
	var layers:Dictionary={}
	for day in int(_arg("days","30")):
		terrain.advance_world_time(1.0)
		await get_tree().process_frame
		for layer in UiMeasure.notice_layers(terrain.hud):layers[layer]=int(layers.get(layer,0))+1
	for i in 3:await get_tree().process_frame
	var at:Vector3=GameState.settlement_founded_at
	var ground:Dictionary=terrain._survey_ground_at(Vector2(at.x,at.z))
	var feed:PackedStringArray=[]
	for e in preload("res://scripts/chronicle.gd").entries("whisper"):feed.append("%s | %s" % [String(e.get("title","")),String(e.get("text",""))])
	var row:={"seed":seed_value,"day":int(GameState.elapsed_days),"biome":String(ground.get("biome","")),"setting":preload("res://tests/fun_audit/founding_probe.gd")._setting(seed_value,ground),"bars":UiMeasure.bars(terrain.hud),"layers":layers,"hud_layers":terrain.hud.get_meta_list(),"feed":feed}
	print("BARS ",JSON.stringify(row))
	get_tree().quit(0)
