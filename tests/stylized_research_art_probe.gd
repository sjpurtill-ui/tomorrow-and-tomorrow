extends Node
const Art=preload("res://scripts/hud/research_visuals.gd")
const IDS=["climate_managed_resettlement","gene_edited_crops","oral_rehydration_salts","moving_assembly_line","stored_program_computer","industrial_robots","hydroelectric_stations","intermodal_shipping_containers","atmospheric_co2_record","civil_rights_law","radio_detection_ranging","radio_broadcasting"]
const BRONZE_IDS=["palace_department_registers","overseas_colony_founding","incubation_shrines","brailed_square_sail","forge_crew_roles","iron_ard_shares","smelter_fuel_depletion_watch","lost_age_remembrance","iron_sword_issue","full_vowel_alphabet","groundwater_tunnels","die_struck_coinage"]
const KEY2_IDS=["marsh_fever_drainage","forced_resettlement","village_self_rule_after_collapse","silver_wage_payment","deep_hold_merchantmen","double_descent_citizenship","dough_leavening","shrine_league_confederation","camel_caravans","town_physicians","oracle_consultation","household_tax_registers"]
const KEY3_IDS=["iron_spear_levy","cataract_couching","shrine_festival_games","annual_elected_magistrates","free_threshing_wheat","citizen_heavy_infantry","written_epic","public_work_tenders","town_consolidation","columned_stone_temple","fluid_balance_theory","two_ended_tunnels","three_banked_warships"]
func _ready()->void:
	assert(OS.get_user_data_dir().ends_with("TomorrowAndTomorrow_StylizedArt_Test"))
	GameState.civic_api_enabled=false
	DiscoverySystem.initialize()
	get_window().size=Vector2i(1440,900)
	get_window().content_scale_size=Vector2i.ZERO
	var paths:Dictionary={}
	var hashes:Dictionary={}
	var grid:=GridContainer.new();grid.columns=3;grid.position=Vector2(18,18);add_child(grid)
	var bronze:bool="--bronze" in OS.get_cmdline_user_args()
	var key2:bool="--key2" in OS.get_cmdline_user_args()
	var key3:bool="--key3" in OS.get_cmdline_user_args()
	var all_early:bool="--all-early" in OS.get_cmdline_user_args()
	var batch:String="all-early" if all_early else ("key3" if key3 else ("key2" if key2 else ("bronze" if bronze else "later")))
	var selected:Array=BRONZE_IDS+KEY2_IDS+KEY3_IDS if all_early else (KEY3_IDS if key3 else (KEY2_IDS if key2 else (BRONZE_IDS if bronze else IDS)))
	if key3:get_window().size=Vector2i(1440,1120)
	for classical_batch:String in ["classical-01","classical-02","classical-03","classical-04","classical-other-01","classical-other-02","classical-other-03","classical-other-04","classical-other-05","classical-other-06","classical-other-07","classical-other-08","classical-other-09"]:
		if "--"+classical_batch in OS.get_cmdline_user_args():
			var selection:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://art_source/research-"+classical_batch+"/selected.json"))
			selected=selection.keys();batch=classical_batch
			assert(selected.size()==(21 if classical_batch in ["classical-04","classical-other-01","classical-other-02","classical-other-03","classical-other-04","classical-other-05","classical-other-06","classical-other-07","classical-other-08","classical-other-09"] else 22))
			get_window().size=Vector2i(1440,1720)
	for early_batch:String in ["earliest-01","earliest-02","earliest-03","earliest-04","earliest-05","earliest-06","earliest-07","earliest-08","earliest-09","earliest-10","earliest-11","earliest-12","earliest-13","earliest-14","earliest-15","earliest-16","earliest-17","earliest-18","earliest-19","earliest-20","earliest-21","earliest-22"]:
		if "--"+early_batch in OS.get_cmdline_user_args():
			batch=early_batch;selected=[]
			var selection:Array=JSON.parse_string(FileAccess.get_file_as_string("res://art_source/research-"+early_batch+"/selected.json"))
			for row:Dictionary in selection:selected.append(row.id)
			assert(selected.size()==({"earliest-01":6,"earliest-02":9,"earliest-03":8,"earliest-04":7,"earliest-05":7,"earliest-06":7,"earliest-07":4,"earliest-08":9,"earliest-09":10,"earliest-10":8,"earliest-11":16,"earliest-12":10,"earliest-13":10,"earliest-14":15,"earliest-15":14,"earliest-16":15,"earliest-17":17,"earliest-18":16,"earliest-19":18,"earliest-20":20,"earliest-21":14,"earliest-22":17}[early_batch]))
	if batch in ["earliest-11","earliest-17","earliest-18","earliest-19","earliest-20","earliest-21","earliest-22"]:get_window().size=Vector2i(1440,1120)
	if batch=="earliest-20":get_window().size=Vector2i(1440,1320)
	for id:String in selected:
		assert(DiscoverySystem.catalog_by_id.has(id),"Missing live discovery: "+id)
		var item:Dictionary=DiscoverySystem.catalog_by_id[id].duplicate(true);item.exposed=true
		var expected:String=Art.manifest()[id].path
		if batch.begins_with("earliest-"):
			for year:float in [1.0,2.0,3.0,4.0,5.0,6.0,7.0,8.0,9.0,10.0,11.0,12.0,13.0,14.0,15.0,16.0,17.0,18.0,20.0,22.0,23.0,24.0,25.0,28.0,30.0,31.0,32.0,34.0,35.0,36.0,38.0,40.0,44.0,45.0,48.0,50.0,52.0,53.0,55.0,56.0,58.0,60.0,62.0,64.0,65.0,66.0,68.0,70.0,72.0,75.0,78.0,80.0,82.0,85.0,88.0,90.0,91.0,92.0,93.0,94.0,95.0,97.0,100.0,102.0,104.0,105.0,106.0,108.0,110.0,112.0,299.0,300.0,600.0]:
				GameState.elapsed_days=year*365.0
				assert(Art.subject_art_key(item)==expected,"Early art overridden at year %s: %s" % [year,id])
			GameState.elapsed_days=365.0
		assert(Art.subject_art_key(item)==expected,"Art lookup overridden: "+id)
		var texture:=Art.for_discovery(item)
		assert(texture is Texture2D and texture.resource_path==expected)
		assert(not paths.has(expected));paths[expected]=true
		var sha:=FileAccess.get_sha256(expected)
		var provenance:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/ui/research/subjects/"+id+".json"))
		assert(sha==provenance.sha256 and not hashes.has(sha));hashes[sha]=true
		for dimensions in [Vector2(708,210),Vector2(264,70)]:
			var crop:=Art.crop_region(texture,dimensions,Art.focus_for(item))
			assert(Rect2(Vector2.ZERO,texture.get_size()).grow(.01).encloses(crop))
		var column:=VBoxContainer.new();grid.add_child(column)
		var painting:=preload("res://scripts/hud/subject_painting.gd").new()
		painting.texture=texture;painting.focus=Art.focus_for(item);painting.custom_minimum_size=Vector2(464,464.0/3.37);column.add_child(painting)
		var label:=Label.new();label.text=String(item.name);column.add_child(label)
		item.exposed=false
		assert(Art.subject_art_key(item).is_empty() and Art.for_discovery(item)==null,"Hidden research reveals art")
	for frame in 4:await get_tree().process_frame
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://artifacts/"+batch+"-research-in-game-crops.png")
	print("STYLIZED_RESEARCH_ART_PASS batch=",batch," count=",selected.size()," live catalog IDs, manifest precedence, unique textures/provenance, hidden gating and banner crops")
	get_tree().quit()
