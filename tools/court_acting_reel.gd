extends "res://tests/court_morning_clip.gd"
## The real court's reel (L's court_morning_clip: the real Court modal, engine,
## director, acting, set and figures) kept as stills at the player's 1536x864,
## a still every half second, for reviewing the acting in M's set. Windowed only,
## on the private desktop, without the movie writer:
##   powershell -File tools/run_isolated_gpu_probe.ps1 ... -Scene res://tools/court_acting_reel.tscn -UserArguments "--only=wrath --tier=0"
## Writes res://reports/court_acting/reel_<only>_<tier>/still_###.png (reports/ is ignored).

const EVERY:=0.5

func _ready()->void:
	if DisplayServer.get_name()!="headless":_keep_stills()
	super._ready()

func _keep_stills()->void:
	var only_:="wrath";var tier_:=0
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--only="):only_=arg.trim_prefix("--only=")
		if arg.begins_with("--tier="):tier_=int(arg.trim_prefix("--tier="))
	var dir:=ProjectSettings.globalize_path("res://reports/court_acting/reel_%s_%d/" % [only_,tier_])
	DirAccess.make_dir_recursive_absolute(dir)
	var n:=0
	while is_inside_tree():
		await get_tree().create_timer(EVERY).timeout
		await RenderingServer.frame_post_draw
		var img:=get_viewport().get_texture().get_image()
		if img!=null and img.get_width()==1536 and img.get_height()==864:
			img.save_png(dir+"still_%03d.png" % n)
			n+=1
