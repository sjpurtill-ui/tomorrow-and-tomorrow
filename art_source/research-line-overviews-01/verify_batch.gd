extends Node
const Art=preload("res://scripts/hud/research_visuals.gd")
func _ready()->void:
	assert(OS.get_user_data_dir().ends_with("TomorrowAndTomorrow_StylizedArt_Test"))
	GameState.civic_api_enabled=false
	DiscoverySystem.initialize()
	var rows:Array=JSON.parse_string(FileAccess.get_file_as_string("res://art_source/research-line-overviews-01/selected.json"))
	assert(rows.size()==12)
	get_window().size=Vector2i(1440,1480)
	get_window().content_scale_size=Vector2i.ZERO
	var grid:=GridContainer.new();grid.columns=3;grid.position=Vector2(12,12);add_child(grid)
	var hashes:Dictionary={}
	for row:Dictionary in rows:
		var texture:Texture2D
		for year:float in [0.0,1.0,299.0,300.0,600.0]:
			GameState.elapsed_days=year*365.0
			texture=Art.art(row.id)
			assert(texture!=null and texture.resource_path==row.path)
		assert(texture.get_width()==row.dimensions[0] and texture.get_height()==row.dimensions[1])
		assert(FileAccess.get_sha256(row.path)==row.sha256 and not hashes.has(row.sha256));hashes[row.sha256]=true
		var column:=VBoxContainer.new();grid.add_child(column)
		var label:=Label.new();label.text=row.id;column.add_child(label)
		var wide:=preload("res://scripts/hud/subject_painting.gd").new()
		wide.texture=texture;wide.focus=Vector2(.5,.5);wide.custom_minimum_size=Vector2(464,464.0/3.37);column.add_child(wide)
		var crops:=HBoxContainer.new();column.add_child(crops)
		for dimensions:Vector2 in [Vector2(92,92),Vector2(230,190)]:
			var crop:=TextureRect.new();crop.texture=texture;crop.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;crop.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED;crop.custom_minimum_size=dimensions;crop.size_flags_vertical=Control.SIZE_SHRINK_BEGIN;crops.add_child(crop)
		for dimensions:Vector2 in [Vector2(464,464.0/3.37),Vector2(92,92),Vector2(230,190)]:
			assert(Rect2(Vector2.ZERO,texture.get_size()).grow(.01).encloses(Art.crop_region(texture,dimensions,Vector2(.5,.5))))
	# Specific discoveries and hidden gating retain their existing priority.
	GameState.elapsed_days=365.0
	var item:Dictionary=DiscoverySystem.catalog_by_id["agreed_signal_codes"].duplicate(true);item.exposed=true
	assert(Art.subject_art_key(item)!= "res://assets/ui/research/knowledge-v1.png")
	item.exposed=false;assert(Art.subject_art_key(item).is_empty())
	for frame in 4:await get_tree().process_frame
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://artifacts/overview01-in-game-crops.png")
	print("OVERVIEW01_ART_PASS count=",rows.size()," effective overview sources across eras, dimensions, hashes, source priority, hidden gating, crop bounds")
	get_tree().quit()
