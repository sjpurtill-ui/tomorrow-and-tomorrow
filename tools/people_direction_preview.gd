extends Node
func _ready()->void:
	PeopleDirection.open_direction()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture="):
			PeopleDirection.panel._refresh()
			await get_tree().create_timer(.5).timeout
			get_viewport().get_texture().get_image().save_png(arg.trim_prefix("--capture="))
			get_tree().quit()
