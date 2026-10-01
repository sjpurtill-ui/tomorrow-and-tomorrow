extends SceneTree
func _initialize()->void:
	call_deferred("verify")
func verify()->void:
	assert(OS.get_user_data_dir().ends_with("TomorrowAndTomorrow_StylizedArt_Test"))
	var art=load("res://scripts/hud/artifact_visuals.gd")
	var paths:Dictionary={}
	for id:int in [1313,1314]:
		var item:Dictionary=load("res://scripts/prehistoric_artifacts.gd").definition(id)
		item["kind"]="artifact"
		var path:String=art.image_path(item)
		assert(path=="res://assets/ui/artifacts/prehistoric-v1/artifact-%04d.png" % id)
		var texture:Texture2D=art.texture(item)
		assert(texture!=null and texture.get_width()<=512 and texture.get_height()<=512)
		assert(not paths.has(path));paths[path]=true
		item["source_id"]="living-civilization"
		assert(art.image_path(item).is_empty(),"Ancient find must not acquire living maker art")
	print("OPENING02_ARTIFACT_PASS count=2 exact sources, distinct textures, import limits, origin separation")
	quit()
