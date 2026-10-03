extends "res://tests/audience_modal_probe.gd"
## How much the modelled court costs a frame, as the player gets it: the real
## Court modal with the director's room, the set, the figures and the acting,
## at 1536x864 with vsync off. For each hall (the fire circle, the longhouse)
## and each kind of audience (one of ours, an envoy with company) it waits
## until everyone has walked in, then measures the stage's 3D view over 90
## frames: CPU and GPU milliseconds, draw calls, objects, and the whole
## frame's process time. Windowed, on a private desktop:
##   powershell -File tools/run_isolated_gpu_probe.ps1 -Godot <godot> -Project <worktree> -Scene res://tests/court_stage_perf_probe.tscn -LogFile <log>
## Prints COURT_PERF lines. Presentation only.

const Backdrop:=preload("res://scripts/hud/court_backdrop.gd")

func _ready()->void:
	capture=DisplayServer.get_name()!="headless"
	_setup_world()
	var terrain:=TerrainDouble.new();terrain.name="TerrainDouble";add_child(terrain)
	var director:=Director.new();director.terrain=terrain;add_child(director)
	if "force_offline" in director.voice:director.voice.force_offline=true
	await _frames(2)
	if capture:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		get_window().size=Vector2i(1536,864);get_window().content_scale_size=Vector2i(1536,864)
		await _frames(3)
	HudTokens.set_color_mode("light")
	for tier in [0,1]:
		Backdrop.tier_override=tier
		await _measure(director,"home",Hall.debug_force("petition"))
		await _measure(director,"envoy",Hall.debug_force("gift"))
	print("COURT_PERF DONE")
	get_tree().quit(0)

func _measure(director:Node,label:String,audience:Dictionary)->void:
	if audience.is_empty():print("COURT_PERF no %s audience" % label);return
	var id:=String(audience.id)
	var modal:Control=director.open_audience(id)
	await _wait_scene(modal,id,1)
	var stage:Control=modal.court_stage
	if not is_instance_valid(stage) or stage.view3d==null:print("COURT_PERF %s: no 3D stage" % label);return
	await get_tree().create_timer(7.0).timeout
	var rid:RID=stage.view3d.get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(rid,true)
	for i in 20:await get_tree().process_frame
	var gpu:=0.0;var cpu:=0.0;var process:=0.0;var n:=0
	var start:=Time.get_ticks_usec()
	for i in 90:
		await get_tree().process_frame
		gpu+=RenderingServer.viewport_get_measured_render_time_gpu(rid)
		cpu+=RenderingServer.viewport_get_measured_render_time_cpu(rid)
		process+=Performance.get_monitor(Performance.TIME_PROCESS)*1000.0
		n+=1
	var wall:=float(Time.get_ticks_usec()-start)/1000.0/float(n)
	var draws:int=stage.view3d.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE,Viewport.RENDER_INFO_DRAW_CALLS_IN_FRAME)
	var objects:int=stage.view3d.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE,Viewport.RENDER_INFO_OBJECTS_IN_FRAME)
	var people:=0
	for key in stage.cast_order:
		var f:Variant=stage.figure(key)
		if f!=null and f.body3d!=null and f.body3d.visible:people+=1
	print("COURT_PERF %s %s people=%d draws=%d objects=%d stage_gpu_ms=%.2f stage_cpu_ms=%.2f process_ms=%.2f frame_ms=%.2f" % [String(stage.court_set.get("kind")) if stage.court_set!=null else "flat",label,people,draws,objects,gpu/float(n),cpu/float(n),process/float(n),wall])
	modal.make_them_wait()
	await _frames(3)
