extends Node
const Art=preload("res://scripts/hud/research_visuals.gd")
const Finds=preload("res://scripts/hud/artifact_visuals.gd")
const Prehistory=preload("res://scripts/prehistoric_artifacts.gd")
const Painting=preload("res://scripts/hud/subject_painting.gd")
func _ready()->void:
	call_deferred("verify")
func verify()->void:
	assert(OS.get_user_data_dir().ends_with("TomorrowAndTomorrow_ArtIntegration_Test"))
	GameState.civic_api_enabled=false
	DiscoverySystem.initialize()
	for child in get_tree().root.get_children():
		if child!=self:child.process_mode=Node.PROCESS_MODE_DISABLED
	if DisplayServer.get_name()!="headless":DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var inventory:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://art_source/art-integration-2026-10-03/inventory.json"))
	var checked:int=0
	for row:Dictionary in inventory.research:
		assert(DiscoverySystem.catalog_by_id.has(row.id),"Missing catalogue ID "+row.id)
		var item:Dictionary=DiscoverySystem.catalog_by_id[row.id].duplicate(true);item.exposed=true
		for year:float in [0.,1.,3.,299.,300.,600.]:
			GameState.elapsed_days=year*365.
			assert(Art.subject_art_key(item)==row.path,"Binding "+row.id+" year "+str(year))
			assert(Art.focus_for(item).is_equal_approx(Vector2(row.focus[0],row.focus[1])),"Focus "+row.id+" year "+str(year))
		var texture:Texture2D=Art.for_discovery(item)
		assert(texture!=null and texture.resource_path==row.path,"Texture "+row.id)
		assert(FileAccess.get_sha256(row.path)==row.sha256,"Source hash "+row.id)
		var sidecar:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/ui/research/subjects/"+row.id+".json"))
		assert(sidecar.sha256==row.sha256,"Provenance "+row.id)
		for slot:Vector2 in [Vector2(708,210),Vector2(264,70)]:
			var crop:=Art.crop_region(texture,slot,Art.focus_for(item))
			assert(crop.size.x>0 and crop.size.y>0 and Rect2(Vector2.ZERO,texture.get_size()).grow(.01).encloses(crop),"Crop "+row.id)
		item.exposed=false;assert(Art.subject_art_key(item).is_empty() and Art.for_discovery(item)==null)
		checked+=1
		if checked%32==0:await get_tree().process_frame
	print("ART_INTEGRATION_RESEARCH_PASS count=",checked," years=0,1,3,299,300,600 bindings/focus/hash/hidden/crops")
	checked=0
	for row:Dictionary in inventory.artifacts:
		var item:Dictionary=Prehistory.definition(int(row.id));item.kind="artifact"
		var expected:="res://assets/ui/artifacts/prehistoric-v1/artifact-%04d.png" % int(row.id)
		assert(Finds.image_path(item)==expected,"Artifact binding "+str(row.id))
		var texture:Texture2D=Finds.texture(item)
		assert(texture!=null and texture.get_width()<=512 and texture.get_height()<=512,"Artifact texture "+str(row.id))
		assert(FileAccess.get_sha256(expected)==row.sha256,"Artifact hash "+str(row.id))
		item.source_id="living-maker";assert(Finds.image_path(item).is_empty())
		checked+=1
		if checked%32==0:await get_tree().process_frame
	print("ART_INTEGRATION_ARTIFACT_PASS count=",checked," approved textures/hash/import limits/origin separation")
	for line:String in inventory.overviews:
		for year:float in [0.,1.,299.,300.,600.]:
			GameState.elapsed_days=year*365.
			var texture:Texture2D=Art.art(line)
			assert(texture!=null and Art.source_path(texture)=="res://assets/ui/research/"+line+"-v1.png","Overview "+line)
	print("ART_INTEGRATION_OVERVIEW_PASS count=12 years=0,1,299,300,600")
	if DisplayServer.get_name()!="headless":
		get_window().size=Vector2i(1440,820);get_window().content_scale_size=Vector2i.ZERO
		for offset:int in [0,maxi(0,inventory.research.size()/2-6),maxi(0,inventory.research.size()-12)]:
			await capture_research(inventory.research.slice(offset,offset+12),"research-"+str(offset))
		await capture_artifacts(inventory.artifacts.slice(-12))
		await capture_overviews(inventory.overviews)
	print("ART_INTEGRATION_COMPLETE images=",inventory.image_files)
	get_tree().quit()
func capture_research(rows:Array,title:String)->void:
	var grid:=GridContainer.new();grid.columns=3;grid.position=Vector2(18,18);add_child(grid)
	for row:Dictionary in rows:
		var box:=VBoxContainer.new();grid.add_child(box)
		var painting:=Painting.new();painting.texture=Art.texture_at(row.path);painting.focus=Vector2(row.focus[0],row.focus[1]);painting.custom_minimum_size=Vector2(464,464./3.37);box.add_child(painting)
		var label:=Label.new();label.text=row.id;box.add_child(label)
	await save_capture(title);grid.queue_free();await get_tree().process_frame
func capture_artifacts(rows:Array)->void:
	var grid:=GridContainer.new();grid.columns=4;grid.position=Vector2(18,18);add_child(grid)
	for row:Dictionary in rows:
		var view:=TextureRect.new();view.texture=load("res://assets/ui/artifacts/prehistoric-v1/artifact-%04d.png" % int(row.id));view.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;view.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;view.custom_minimum_size=Vector2(240,240);grid.add_child(view)
	await save_capture("artifacts");grid.queue_free();await get_tree().process_frame
func capture_overviews(lines:Array)->void:
	var grid:=GridContainer.new();grid.columns=3;grid.position=Vector2(18,18);add_child(grid)
	for line:String in lines:
		var box:=VBoxContainer.new();grid.add_child(box)
		var painting:=Painting.new();painting.texture=Art.art(line);painting.focus=Vector2(.5,.5);painting.custom_minimum_size=Vector2(464,464./3.37);box.add_child(painting)
		var label:=Label.new();label.text=line;box.add_child(label)
	await save_capture("overviews");grid.queue_free();await get_tree().process_frame
func save_capture(title:String)->void:
	for frame in 4:await get_tree().process_frame
	await RenderingServer.frame_post_draw
	assert(get_viewport().get_texture().get_image().save_png("res://artifacts/art-integration-"+title+".png")==OK)
