extends Node
const Art=preload("res://scripts/hud/research_visuals.gd")
const IDS=["climate_managed_resettlement","gene_edited_crops","oral_rehydration_salts","moving_assembly_line","stored_program_computer","industrial_robots","hydroelectric_stations","intermodal_shipping_containers","atmospheric_co2_record","civil_rights_law","radio_detection_ranging","radio_broadcasting"]
func _ready()->void:
	assert(OS.get_user_data_dir().ends_with("TomorrowAndTomorrow_StylizedArt_Test"))
	GameState.civic_api_enabled=false
	DiscoverySystem.initialize()
	get_window().size=Vector2i(1440,900)
	get_window().content_scale_size=Vector2i.ZERO
	var paths:Dictionary={}
	var hashes:Dictionary={}
	var grid:=GridContainer.new();grid.columns=3;grid.position=Vector2(18,18);add_child(grid)
	for id:String in IDS:
		assert(DiscoverySystem.catalog_by_id.has(id),"Missing live discovery: "+id)
		var item:Dictionary=DiscoverySystem.catalog_by_id[id].duplicate(true);item.exposed=true
		var expected:String=Art.manifest()[id].path
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
		painting.texture=texture;painting.focus=Art.focus_for(item);painting.custom_minimum_size=Vector2(464,174);column.add_child(painting)
		var label:=Label.new();label.text=String(item.name);column.add_child(label)
		item.exposed=false
		assert(Art.subject_art_key(item).is_empty() and Art.for_discovery(item)==null,"Hidden research reveals art")
	for frame in 4:await get_tree().process_frame
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://artifacts/stylized-research-in-game-crops.png")
	print("STYLIZED_RESEARCH_ART_PASS 12 live catalog IDs, manifest precedence, unique textures/provenance, hidden gating and banner crops")
	get_tree().quit()
