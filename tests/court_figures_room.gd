extends "res://tests/audience_modal_probe.gd"
## The figures in the real Court, for review (figures, J): a petition opened
## in the fire circle (--tier=0) or the longhouse (--tier=1), a still of the
## whole card and one of the hall, and each person's look printed (hair,
## skin, build, stance), so variety within one people can be checked by eye
## and in the log. Windowed, on a private desktop (tools/run_isolated_gpu_probe.ps1).

const Backdrop:=preload("res://scripts/hud/court_backdrop.gd")

var tier:=0
var tag:="room"

func _ready()->void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--tier="):tier=int(arg.trim_prefix("--tier="))
		if arg.begins_with("--tag="):tag=arg.trim_prefix("--tag=")
	capture=DisplayServer.get_name()!="headless"
	Backdrop.tier_override=tier
	_setup_world()
	var terrain:=TerrainDouble.new();terrain.name="TerrainDouble";add_child(terrain)
	var director:=Director.new();director.terrain=terrain;add_child(director)
	if "force_offline" in director.voice:director.voice.force_offline=true
	await _frames(2)
	if capture:
		get_window().size=Vector2i(1536,864);get_window().content_scale_size=Vector2i(1536,864)
		await _frames(3)
	HudTokens.set_color_mode("light")
	var audience:=Hall.debug_force("petition")
	if audience.is_empty():
		_fail("no petition")
	else:
		var id:=String(audience.id)
		var modal:Control=director.open_audience(id)
		await _wait_scene(modal,id,1)
		await get_tree().create_timer(4.0).timeout
		var stage:Control=modal.court_stage
		for key in stage.cast_order:
			var f=stage.figure(key)
			if f==null or f.body3d==null:continue
			var look:Dictionary=f.body3d.look
			print("LOOK %s %s age=%s %s hair=%s/%s skin=%s build=%s tall=%.3f stance=%s" % [key,String(f.person.get("name","")),f.person.get("age","?"),look.get("variant",""),look.get("hair",""),Color(look.get("hair_colour",Color.BLACK)).to_html(false),Color(look.get("skin",Color.BLACK)).to_html(false),look.get("build",""),float(look.get("tall",1.0)),f.body3d.stance])
		if capture:
			await RenderingServer.frame_post_draw
			var dir:=ProjectSettings.globalize_path("res://reports/court_figures/")
			DirAccess.make_dir_recursive_absolute(dir)
			var image:=get_viewport().get_texture().get_image()
			image.save_png(dir+"room_%s_tier%d.png" % [tag,tier])
			var view:Viewport=stage.view3d
			view.get_texture().get_image().save_png(dir+"room_%s_tier%d_hall.png" % [tag,tier])
			print("CAPTURE ",dir+"room_%s_tier%d.png" % [tag,tier])
	print("COURT_FIGURES_ROOM PASS" if failures.is_empty() else "COURT_FIGURES_ROOM FAIL")
	get_tree().quit(0 if failures.is_empty() else 1)
