extends Node
func _ready()->void:
	HistoricalFigures.open_chronicle()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture="):
			await get_tree().create_timer(.5).timeout
			get_viewport().get_texture().get_image().save_png(arg.trim_prefix("--capture="))
			get_tree().quit()
