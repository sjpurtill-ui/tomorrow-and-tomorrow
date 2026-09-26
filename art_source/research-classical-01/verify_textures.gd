extends SceneTree

func _initialize() -> void:
	var selected_file := FileAccess.open("res://art_source/research-classical-01/selected.json", FileAccess.READ)
	var manifest_file := FileAccess.open("res://assets/ui/research/subject-art-manifest.json", FileAccess.READ)
	if selected_file == null or manifest_file == null:
		printerr("Missing selection or manifest")
		quit(1)
		return
	var selected: Dictionary = JSON.parse_string(selected_file.get_as_text())
	var manifest: Dictionary = JSON.parse_string(manifest_file.get_as_text())
	for subject in selected:
		if not manifest.has(subject):
			printerr("Manifest missing ", subject)
			quit(1)
			return
		var path: String = manifest[subject]["path"]
		var texture := load(path) as Texture2D
		if texture == null or texture.get_width() < 708 or texture.get_height() < 210:
			printerr("Texture failed ", subject, " ", path)
			quit(1)
			return
	print("22 Classical textures load")
	quit()
