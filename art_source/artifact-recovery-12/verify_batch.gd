extends Node
func _ready()->void:
	call_deferred("verify")
func verify()->void:
	assert(OS.get_user_data_dir().ends_with("TomorrowAndTomorrow_ArtifactRecovery_Test"))
	var art=load("res://scripts/hud/artifact_visuals.gd")
	var rows:Array=JSON.parse_string(FileAccess.get_file_as_string("res://art_source/artifact-recovery-12/reviewed.json"))
	var manifest:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://art_source/prehistoric-art/manifest.json"))
	get_window().content_scale_size=Vector2i.ZERO
	var hashes:Dictionary={}
	var grid:=GridContainer.new();grid.columns=4;grid.position=Vector2(16,16);add_child(grid)
	var visible_rows:=mini(rows.size(),12)
	get_window().size=Vector2i(1040,280*ceili(visible_rows/4.0)+20)
	for row:Dictionary in rows:
		var id:=int(row.id)
		var record:Dictionary=load("res://scripts/prehistoric_artifacts.gd").definition(id)
		record["kind"]="artifact"
		var expected:="res://assets/ui/artifacts/prehistoric-v1/artifact-%04d.png" % id
		assert(art.image_path(record)==expected)
		var texture:Texture2D=art.texture(record)
		assert(texture!=null and texture.get_width()<=512 and texture.get_height()<=512)
		var digest:=FileAccess.get_sha256(expected)
		assert(digest==String(manifest.entries[id].sha256) and not hashes.has(digest));hashes[digest]=true
		assert(manifest.entries[id].status=="approved")
		if rows.find(row)>=rows.size()-visible_rows:
			var column:=VBoxContainer.new();grid.add_child(column)
			var view:=TextureRect.new();view.texture=texture;view.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
			view.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;view.custom_minimum_size=Vector2(240,240);column.add_child(view)
			var label:=Label.new();label.text="%04d - %s" % [id,String(record.name).left(26)];column.add_child(label)
		record["source_id"]="living-maker"
		assert(art.image_path(record).is_empty())
	for frame in 4:await get_tree().process_frame
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://artifacts/artifact-recovery12-in-game.png")
	print("ARTIFACT_RECOVERY12_PASS count=",rows.size()," exact approved textures, distinct provenance, import limits, origin separation")
	get_tree().quit()
