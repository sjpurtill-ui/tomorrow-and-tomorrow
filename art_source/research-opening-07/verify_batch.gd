extends Node
const Art=preload("res://scripts/hud/research_visuals.gd")
func _ready()->void:
	assert(OS.get_user_data_dir().ends_with("TomorrowAndTomorrow_StylizedArt_Test"))
	GameState.civic_api_enabled=false
	DiscoverySystem.initialize()
	GameState.elapsed_days=6.0*365.0
	assert(Art.focus_for({"id":"agreed_signal_codes"}).is_equal_approx(Vector2(.5,.5)))
	var rows:Array=JSON.parse_string(FileAccess.get_file_as_string("res://art_source/research-opening-07/selected.json"))
	assert(not rows.is_empty())
	rows.append({"id":"sightline_staking","focus":[.5,.4]})
	rows.append({"id":"streambank_vegetation_watch","focus":[.5,.5]})
	var grid:=GridContainer.new();grid.columns=3;grid.position=Vector2(18,18);add_child(grid)
	get_window().size=Vector2i(1440,1100)
	get_window().content_scale_size=Vector2i.ZERO
	var paths:Dictionary={};var hashes:Dictionary={}
	for row:Dictionary in rows:
		assert(DiscoverySystem.catalog_by_id.has(row.id))
		var item:Dictionary=DiscoverySystem.catalog_by_id[row.id].duplicate(true);item.exposed=true
		var expected:String=Art.manifest()[row.id].path
		for year:float in [0.0,1.0,3.0,299.0,300.0,600.0]:
			GameState.elapsed_days=year*365.0
			assert(Art.subject_art_key(item)==expected,"Wrong effective source: "+row.id)
			assert(Art.focus_for(item).is_equal_approx(Vector2(row.focus[0],row.focus[1])))
		GameState.elapsed_days=6.0*365.0
		var texture:=Art.for_discovery(item)
		assert(texture!=null and texture.resource_path==expected and not paths.has(expected));paths[expected]=true
		var provenance:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/ui/research/subjects/"+row.id+".json"))
		var digest:=FileAccess.get_sha256(expected)
		assert(digest==provenance.sha256 and not hashes.has(digest));hashes[digest]=true
		for dimensions:Vector2 in [Vector2(708,210),Vector2(264,70)]:
			assert(Rect2(Vector2.ZERO,texture.get_size()).grow(.01).encloses(Art.crop_region(texture,dimensions,Art.focus_for(item))))
		var column:=VBoxContainer.new();grid.add_child(column)
		var painting:=preload("res://scripts/hud/subject_painting.gd").new()
		painting.texture=texture;painting.focus=Art.focus_for(item);painting.custom_minimum_size=Vector2(464,464.0/3.37);column.add_child(painting)
		var label:=Label.new();label.text=String(item.name);column.add_child(label)
		item.exposed=false;assert(Art.subject_art_key(item).is_empty() and Art.for_discovery(item)==null)
	for frame in 4:await get_tree().process_frame
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://artifacts/opening07-research-in-game-crops.png")
	print("OPENING07_ART_PASS count=",rows.size()," live IDs, effective sources, focus, hashes, hidden gating, crop bounds")
	get_tree().quit()
