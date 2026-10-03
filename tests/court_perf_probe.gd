extends Node3D
## What the modelled court costs a frame (figures, J): M's longhouse and N
## people in it, lit, idling, with K's acting on them, at 1536x864; the GPU
## and CPU time of the frame measured by the RenderingServer, averaged over
## a few seconds. Each switch turns one thing off, to find the cost:
##   --n=8 --acting=0|1 --ink=0|1 --shadows=0|1 --figures=0|1 --tag=name
## Windowed, on a private desktop (tools/run_isolated_gpu_probe.ps1).
## Prints COURT_PERF <tag> gpu_ms cpu_ms process_ms fps.

const CourtSet:=preload("res://scripts/hud/court_set_3d.gd")
const Figure3D:=preload("res://scripts/hud/court_figure_3d.gd")
const Acting:=preload("res://scripts/hud/court_acting.gd")

var opts:={"n":8,"acting":1,"ink":1,"shadows":1,"figures":1,"tag":"all","anim":1,"hidden":1,"morph":1,"simple":0,"msaa":-1,"lightshadows":1,"omni":1,"mods":1,"skin":1,"only_body":0,"merge":1}

func _ready()->void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--") and arg.contains("="):
			var key:=arg.trim_prefix("--").get_slice("=",0);var value:=arg.get_slice("=",1)
			opts[key]=value if key=="tag" else int(value)
	get_window().size=Vector2i(1536,864)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var court:Node3D=CourtSet.build("tier_1",{"food":0.7,"tier":1})
	add_child(court)
	await get_tree().process_frame
	Figure3D.set_key_light(court.call("key_dir"))
	var looks:=[["male_adult","cropped","beard_short"],["female_adult","braids",""],["male_old","balding","beard_long"],["female_old","bun",""],
		["male_young","topknot",""],["female_young","long_framed",""],["male_adult","long","beard_stubble"],["female_adult","tail",""]]
	var marks:=["petitioner","officials_0","officials_1","officials_2","officials_3","officials_4","officials_5","crowd_0"]
	var made:=[]
	const Merge:=preload("res://scripts/hud/court_figure_merge.gd")
	Merge.enabled=int(opts.merge)==1
	var t_setup:=Time.get_ticks_usec()
	if int(opts.figures)==1:
		for i in int(opts.n):
			var fig:=Figure3D.new()
			court.add_child(fig)
			var spec:Array=looks[i%looks.size()]
			fig.setup({"variant":spec[0],"outfit":"tunic","hair":spec[1],"beard":spec[2],"skin":Color("9f6a43"),"hair_colour":Color("2b2018"),
				"cloth":[Color("a8432f"),Color("6e5541"),Color("c9a43c")],"stance":"stand","lit":true,"face":{"jaw":0.3},"years":30+i*5})
			court.call("place",fig,marks[i%marks.size()])
			fig.play(fig.rest_clip(),0.0,0.4*float(i))
			if int(opts.ink)==0:
				for m in fig.find_children("*","MeshInstance3D",true,false):
					var mi:=m as MeshInstance3D
					if mi.mesh==null:continue
					for s in mi.mesh.get_surface_count():
						var mat:=mi.get_surface_override_material(s) as ShaderMaterial
						if mat!=null and mat.next_pass!=null:
							var bare:=mat.duplicate() as ShaderMaterial;bare.next_pass=null
							mi.set_surface_override_material(s,bare)
			if int(opts.shadows)==0:
				for m in fig.find_children("*","MeshInstance3D",true,false):(m as MeshInstance3D).cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			if int(opts.acting)==1:
				Acting.set_mood(fig,"neutral")
			if int(opts.hidden)==0:
				for m in fig.find_children("*","MeshInstance3D",true,false):
					if not (m as MeshInstance3D).visible:m.queue_free()
			if int(opts.morph)==0:
				for m in fig.find_children("*","MeshInstance3D",true,false):
					var mi:=m as MeshInstance3D
					if mi.mesh!=null:
						for b in mi.get_blend_shape_count():mi.set_blend_shape_value(b,0.0)
			if int(opts.mods)==0:
				for m in fig.find_children("*","SkeletonModifier3D",true,false):m.queue_free()
			if int(opts.skin)==0:
				for m in fig.find_children("*","MeshInstance3D",true,false):
					var mi:=m as MeshInstance3D
					var keep:=mi.global_transform
					mi.skeleton=NodePath("");mi.skin=null
			if int(opts.only_body)==1:
				for m in fig.find_children("*","MeshInstance3D",true,false):(m as MeshInstance3D).visible=String(m.name)=="Body"
			if int(opts.simple)==1:
				var plain:=StandardMaterial3D.new();plain.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;plain.albedo_color=Color(0.6,0.4,0.3)
				for m in fig.find_children("*","MeshInstance3D",true,false):(m as MeshInstance3D).material_override=plain
			if i==0:
				var total:=0
				for m in fig.find_children("*","MeshInstance3D",true,false):
					var mi:=m as MeshInstance3D
					if mi.mesh==null:continue
					var tris:=0
					for s2 in mi.mesh.get_surface_count():tris+=mi.mesh.surface_get_array_index_len(s2)/3
					if mi.visible:total+=tris
					print("MESH %s visible=%s tris=%d shapes=%d" % [mi.name,mi.visible,tris,mi.mesh.get_blend_shape_count()])
				print("VISIBLE_TRIS ",total)
			made.append(fig)
	print("SETUP_MS %.1f" % (float(Time.get_ticks_usec()-t_setup)/1000.0))
	var cam:Camera3D=court.get("camera")
	for l in court.find_children("*","Light3D",true,false):
		var light:=l as Light3D
		print("LIGHT %s %s shadow=%s energy=%.2f" % [light.name,light.get_class(),light.shadow_enabled,light.light_energy])
		if int(opts.lightshadows)==0:light.shadow_enabled=false
		if int(opts.omni)==0 and not light is DirectionalLight3D:light.visible=false
	await get_tree().process_frame
	var subjects:=[]
	for f in made:subjects.append(f)
	cam.call("wide",subjects if not subjects.is_empty() else [Vector3.ZERO],0.0)
	if int(opts.msaa)>=0:get_viewport().msaa_3d=int(opts.msaa) as Viewport.MSAA
	print("MSAA ",get_viewport().msaa_3d," scaling ",get_viewport().scaling_3d_scale)
	var vp:=get_viewport().get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(vp,true)
	if int(opts.anim)==0:
		for f in made:
			f.player.pause()
	for i in 90:await get_tree().process_frame
	var gpu:=0.0;var cpu:=0.0;var proc:=0.0;var frames:=0
	var t0:=Time.get_ticks_usec()
	while frames<240:
		await get_tree().process_frame
		gpu+=RenderingServer.viewport_get_measured_render_time_gpu(vp)
		cpu+=RenderingServer.viewport_get_measured_render_time_cpu(vp)+RenderingServer.get_frame_setup_time_cpu()
		proc+=Performance.get_monitor(Performance.TIME_PROCESS)*1000.0
		frames+=1
	var wall:=float(Time.get_ticks_usec()-t0)/1000000.0
	var tris:=RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)
	var draws:=RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
	print("COURT_PERF %s gpu_ms=%.2f cpu_ms=%.2f process_ms=%.2f fps=%.0f prims=%d draws=%d" % [String(opts.tag),gpu/frames,cpu/frames,proc/frames,float(frames)/wall,tris,draws])
	get_tree().quit(0)
