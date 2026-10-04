extends Node
## Exhaustive cloth-edge and view-dependent skin-cover diagnostics. No renderer,
## simulation changes or body edits. Python consumes the exported mesh/pose stream.
const Figure=preload("res://scripts/hud/court_figure_3d.gd")
const Acting=preload("res://scripts/hud/court_acting.gd")
const Audit=preload("res://tools/court_acting_audit.gd")
const TIMES:=[0.0,.2,.4,.65,.9,1.2,1.6]

func _ready()->void:
	var variants:=["male_adult","female_old"];var outfits:=["hide","tunic","robe"]
	var label:="baseline"
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--bodies="):variants=arg.trim_prefix("--bodies=").split(",")
		if arg.begins_with("--outfits="):outfits=arg.trim_prefix("--outfits=").split(",")
		if arg.begins_with("--label="):label=arg.trim_prefix("--label=").validate_filename()
	var dir:=ProjectSettings.globalize_path("res://reports/court_legacy_motion/");DirAccess.make_dir_recursive_absolute(dir)
	var file:=FileAccess.open(dir+label+".jsonl",FileAccess.WRITE);var count:=0
	for variant:String in variants:
		var source:=Figure.scene_for(variant).instantiate()
		var source_body:MeshInstance3D=null
		for node:MeshInstance3D in source.find_children("*","MeshInstance3D",true,false):
			if node.name==&"Body":source_body=node;break
		var source_arrays:=Audit._surface(source_body);var source_colors:Dictionary={}
		for vertex in source_arrays.v.size():source_colors[_key(source_arrays.v[vertex])]=source_arrays.c[vertex]
		for outfit:String in outfits:
			var f:=Figure.new();add_child(f);f.setup({"variant":variant,"outfit":outfit,"lit":false,"hair":"cropped","stance":"stand"})
			f.player.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
			var acting=Acting.of(f);acting.active=false
			var body:MeshInstance3D=null;var pieces:Array=[]
			for part:MeshInstance3D in f._parts:
				if part.name==&"Body":body=part
				elif part.visible and String(part.name).begins_with(outfit+"_"):pieces.append(part)
			var bp:=Audit._new_probe("body","points");var bs:=Audit._surface(body)
			for vertex in bs.v.size():Audit._add_vertex(bp,body,f.skeleton,bs,vertex)
			Audit._finish(bp)
			var hidden:=[];var newly_hidden:=[];var mismatches:=0
			for vertex in bs.v.size():
				var key:=_key(bs.v[vertex]);var current:=_mask(bs.c[vertex],outfit)
				if not source_colors.has(key):mismatches+=1;continue
				if current>.5:hidden.append(vertex)
				if current>.5 and _mask(source_colors[key],outfit)<=.5:newly_hidden.append(vertex)
			var probes:Array=[];var metadata:Array=[]
			for part:MeshInstance3D in pieces:
				var surface:=Audit._surface(part);var probe:=Audit._new_probe(String(part.name),"points")
				for vertex in surface.v.size():Audit._add_vertex(probe,part,f.skeleton,surface,vertex)
				Audit._finish(probe);probes.append(probe)
				metadata.append({"name":part.name,"rest":_vectors(Audit._skin(probe,Audit._pose(f.skeleton,true))),"triangles":surface.i})
			file.store_line(JSON.stringify({"kind":"mesh","variant":variant,"outfit":outfit,"height":f._base_height,
				"body_triangles":bs.i,"hidden":hidden,"newly_hidden":newly_hidden,"body_position_mismatches":mismatches,"pieces":metadata}))
			for clip:String in ["walk_in","walk_out","sit","kneel","sit_cross","kneel_release","sit_cross_release"]:
				Audit._reset(f,acting)
				if clip.begins_with("kneel") or clip.begins_with("sit_cross"):
					f.play("stand",0.0,0.0);Acting.play(f,clip.trim_suffix("_release"),{"blend":0.0})
					if clip.ends_with("_release"):
						for frame in 48:Audit._frame(f,acting)
						Acting.stop(f,.45);f.play("walk_out",0.0,0.0)
				else:f.play(clip,0.0,0.0)
				var now:=0.0
				for target:float in TIMES:
					while now+Audit.DT*.5<target:Audit._frame(f,acting);now+=Audit.DT
					f.skeleton.force_update_all_bone_transforms();var pose:=Audit._pose(f.skeleton,false);var cloth:Array=[]
					for probe:Dictionary in probes:cloth.append(_vectors(Audit._skin(probe,pose)))
					file.store_line(JSON.stringify({"kind":"pose","variant":variant,"outfit":outfit,"clip":clip,"time":now,"body":_vectors(Audit._skin(bp,pose)),"pieces":cloth}))
					count+=1
			f.free()
		source.free()
	file.close();print("LEGACY_MOTION_EXPORT poses=",count," path=",dir+label+".jsonl");get_tree().quit()

static func _key(p:Vector3)->String:return "%.6f:%.6f:%.6f" % [p.x,p.y,p.z]
static func _mask(c:Color,outfit:String)->float:return c.g if outfit=="hide" else (c.b if outfit=="tunic" else c.a)
static func _vectors(points:PackedVector3Array)->Array:
	var result:=[]
	for p:Vector3 in points:result.append([p.x,p.y,p.z])
	return result
