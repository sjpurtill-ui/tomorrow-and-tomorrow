extends Node
## Export the real skinned hands and complete skirt triangles through a stride.
## Consumed by validate_court_walking_cloth.py; no viewport or player save.
const Figure:=preload("res://scripts/hud/court_figure_3d.gd")
const Acting:=preload("res://scripts/hud/court_acting.gd")
const Audit:=preload("res://tools/court_acting_audit.gd")
const Clearance:=preload("res://scripts/hud/court_walk_clearance.gd")

func _ready()->void:
	var directory:=ProjectSettings.globalize_path("res://reports/court_wardrobe_walk/")
	DirAccess.make_dir_recursive_absolute(directory)
	var lower_shell:="--lower-shell" in OS.get_cmdline_user_args()
	var bare_body:="--bare-body" in OS.get_cmdline_user_args()
	var filename:="bare-body.jsonl" if bare_body else ("lower-shell.jsonl" if lower_shell else "poses.jsonl")
	var file:=FileAccess.open(directory+filename,FileAccess.WRITE)
	var count:=0
	var phases:=32
	for argument:String in OS.get_cmdline_user_args():
		if argument.begins_with("--phases="):phases=maxi(16,int(argument.trim_prefix("--phases=")))
	for variant:String in Figure.BODIES:
		var chosen:=""
		for argument:String in OS.get_cmdline_user_args():
			if argument.begins_with("--variant="):chosen=argument.trim_prefix("--variant=")
		if not chosen.is_empty() and not variant in chosen.split(","):continue
		for outfit:String in ["hide","tunic","robe","medieval","courtcoat","formal","business"]:
			var selected_outfit:=""
			for argument:String in OS.get_cmdline_user_args():
				if argument.begins_with("--outfit="):selected_outfit=argument.trim_prefix("--outfit=")
			if not selected_outfit.is_empty() and not outfit in selected_outfit.split(","):continue
			if bare_body and outfit!="medieval":continue
			var f:=Figure.new();add_child(f);f.setup({"variant":variant,"outfit":outfit})
			for argument:String in OS.get_cmdline_user_args():
				if argument.begins_with("--arm-clearance="):
					Clearance.configure(f.player,f.skeleton,variant,outfit,float(argument.trim_prefix("--arm-clearance=")))
			f.player.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
			var acting=Acting.of(f);acting.active=false
			var hands:=Audit._new_probe("hands","points")
			var hand_triangles:=PackedInt32Array()
			var cloth:=Audit._new_probe("skirt","points")
			var triangles:=PackedInt32Array()
			for part:MeshInstance3D in f._parts:
				var selected:=String(part.name)==outfit+"_trousers" if lower_shell else String(part.name).begins_with(outfit+"_skirt_")
				if outfit=="business":selected=String(part.name)=="business_trousers"
				if outfit in ["hide","tunic","robe"]:selected=String(part.name)==outfit+("_wrap" if outfit=="hide" else "_body")
				if bare_body:selected=false
				if part.name!=&"Body" and not selected:continue
				var surface:=Audit._surface(part)
				if part.name==&"Body":
					var kept:Dictionary={}
					var lower:Dictionary={}
					for vertex in surface.v.size():
						var hand_weight:=0.0
						var leg_weight:=0.0
						for j in 4:
							var bind:int=surface.b[vertex*4+j]
							var bone:=part.skin.get_bind_bone(bind)
							var name:=String(f.skeleton.get_bone_name(bone)) if bone>=0 else String(part.skin.get_bind_name(bind))
							if name.get_slice(".",0) in ["hand","thumb","index","fingers"]:hand_weight+=surface.w[vertex*4+j]
							if name.get_slice(".",0) in ["hips","thigh","shin","foot","toe"]:leg_weight+=surface.w[vertex*4+j]
						if hand_weight>.6:
							kept[vertex]=hands.verts.size()
							Audit._add_vertex(hands,part,f.skeleton,surface,vertex)
						if bare_body and leg_weight>.5:
							lower[vertex]=cloth.verts.size()
							Audit._add_vertex(cloth,part,f.skeleton,surface,vertex)
					for index in range(0,surface.i.size(),3):
						var a:int=surface.i[index];var b:int=surface.i[index+1];var c:int=surface.i[index+2]
						if kept.has(a) and kept.has(b) and kept.has(c):hand_triangles.append_array([kept[a],kept[b],kept[c]])
						if bare_body and lower.has(a) and lower.has(b) and lower.has(c):triangles.append_array([lower[a],lower[b],lower[c]])
				else:
					var base:int=cloth.verts.size()
					for vertex in surface.v.size():Audit._add_vertex(cloth,part,f.skeleton,surface,vertex)
					for triangle in range(0,surface.i.size(),3):
						var a:int=surface.i[triangle];var b:int=surface.i[triangle+1];var c:int=surface.i[triangle+2]
						# Restrict legacy full garments to the hip/leg region. Their
						# sleeve cuffs intentionally meet the wrists.
						if outfit in ["hide","tunic","robe"] and maxf(surface.v[a].y,maxf(surface.v[b].y,surface.v[c].y))>f._base_height*.62:continue
						triangles.append_array([base+a,base+b,base+c])
			Audit._finish(hands);Audit._finish(cloth)
			for clip:String in ["walk_in","walk_out"]:
				Audit._reset(f,acting);f.play(clip,0.0,0.0);f.player.advance(0.0)
				var length:float=f.player.get_animation(clip).length
				for phase in phases:
					var at:=length*float(phase)/float(phases)
					f.player.seek(at,true);f.skeleton.force_update_all_bone_transforms()
					var pose:=Audit._pose(f.skeleton,false)
					file.store_line(JSON.stringify({"variant":variant,"outfit":outfit,"clip":clip,"time":at,
						"hands":_vectors(Audit._skin(hands,pose)),"hand_triangles":hand_triangles,
						"cloth":_vectors(Audit._skin(cloth,pose)),"triangles":triangles}))
					count+=1
			f.free()
	file.close()
	print("WARDROBE_WALK_EXPORT poses=",count," path=",directory+filename)
	get_tree().quit()

static func _vectors(points:PackedVector3Array)->Array:
	var out:=[]
	for point:Vector3 in points:out.append([point.x,point.y,point.z])
	return out
