extends "res://tests/court_progression_pose_capture.gd"
## Same pose/material/camera with alternative outline extrusion only.
const LEGACY:="""
	vec4 clip = PROJECTION_MATRIX * (MODELVIEW_MATRIX * vec4(VERTEX, 1.0));
	vec3 nv = normalize((MODELVIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
	vec2 nc = (PROJECTION_MATRIX * vec4(nv, 0.0)).xy;
	float l = length(nc);
	if (l > 1e-5) {
		clip.xy += nc / l * width_px * 2.0 / VIEWPORT_SIZE * clip.w;
	}
	POSITION = clip;
"""
var failures:Array[String]=[]

func _ready()->void:
	if "unmerged" in OS.get_cmdline_user_args():Figure3D.Merge.enabled=false
	await super._ready()

func _shot(file:String)->void:
	var tag:="unmerged" if "unmerged" in OS.get_cmdline_user_args() else "merged"
	if "orthographic" in OS.get_cmdline_user_args():tag+="-orthographic"
	var destination:=ProjectSettings.globalize_path("res://reports/court_figure_ink/"+tag+"/")
	DirAccess.make_dir_recursive_absolute(destination)
	var old_projection:=camera.projection
	if "orthographic" in OS.get_cmdline_user_args():
		camera.size=2.0*1.1*tan(deg_to_rad(camera.fov*0.5))
		camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	var entries:Array=[]
	for figure in figures:
		for mesh:MeshInstance3D in figure.find_children("*","MeshInstance3D",true,false):
			if not mesh.is_visible_in_tree() or mesh.mesh==null:continue
			for surface in mesh.mesh.get_surface_count():
				var material:=mesh.get_active_material(surface) as ShaderMaterial
				if material==null or material.next_pass==null:continue
				entries.append([mesh,surface,material])
	var rendered:Dictionary={}
	for mode in ["legacy","fixed","none"]:
		for entry in entries:
			var base:ShaderMaterial=entry[2]
			var material:=base.duplicate() as ShaderMaterial
			if mode=="none":material.next_pass=null
			elif mode=="legacy":
				var outline:=base.next_pass.duplicate() as ShaderMaterial
				var source:String=outline.shader.code.replace("\r\n","\n")
				var start:=source.find("\tvec3 view_position =")
				var finish:=source.find("\tPOSITION = clip;",start)+"\tPOSITION = clip;".length()
				assert(start>=0 and finish>start,"Ink diagnostic could not locate extrusion")
				var shader:=Shader.new();shader.code=source.substr(0,start)+LEGACY+source.substr(finish)
				outline.shader=shader;material.next_pass=outline
			entry[0].set_surface_override_material(entry[1],material)
		await _frames(3)
		await RenderingServer.frame_post_draw
		var shot:=get_viewport().get_texture().get_image()
		shot.save_png(destination+file.trim_suffix(".png")+"-"+mode+".png")
		rendered[mode]=shot
	for entry in entries:entry[0].set_surface_override_material(entry[1],entry[2])
	camera.projection=old_projection
	if tag=="merged" and file=="business_male_adult_seated_close.png":_verify_chest_and_silhouette(rendered)
	print("COURT_INK_CAPTURE ",tag," ",file," errors=",failures)

func _darkened(inked:Image,plain:Image,area:Rect2i)->int:
	var count:=0
	for y in range(area.position.y,area.end.y):
		for x in range(area.position.x,area.end.x):
			var a:=plain.get_pixel(x,y);var b:=inked.get_pixel(x,y)
			if (a.r+a.g+a.b-b.r-b.g-b.b)/3.0>35.0/255.0:count+=1
	return count

func _verify_chest_and_silhouette(shots:Dictionary)->void:
	var chest:=[Rect2i(550,770,88,70),Rect2i(907,748,70,100)]
	var edges:=[Rect2i(380,690,45,130),Rect2i(985,690,175,125)]
	var before:=0;var after:=0;var outline_before:=0;var outline_after:=0
	for patch:Rect2i in chest:
		before+=_darkened(shots.legacy,shots.none,patch)
		after+=_darkened(shots.fixed,shots.none,patch)
	for patch:Rect2i in edges:
		outline_before+=_darkened(shots.legacy,shots.none,patch)
		outline_after+=_darkened(shots.fixed,shots.none,patch)
	print("COURT_INK_PIXELS chest=",before,"->",after," silhouette=",outline_before,"->",outline_after)
	if before<150:failures.append("baseline no longer reproduces the chest regression")
	if after>int(float(before)*0.15):failures.append("internal chest ink was not resolved")
	if outline_after<int(float(outline_before)*0.95):failures.append("outer silhouette lost ink")
	assert(failures.is_empty(),str(failures))
