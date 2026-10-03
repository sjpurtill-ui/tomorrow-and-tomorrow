extends "res://tools/court_acting_audit.gd"
## Detailed companion to the acting audit. Prints the rest-space edge and
## skinning weights behind a deformation failure, without changing its limits.
## godot --headless --path <worktree> res://tools/court_clothing_diagnose.tscn

func _ready()->void:
	var args:=OS.get_cmdline_user_args()
	var variant:=String(args[0]) if args.size()>0 else "female_old"
	var clip:=String(args[1]) if args.size()>1 else "sit_floor"
	var fig:Node3D=Figure3D.new()
	add_child(fig)
	fig.setup({"variant":variant,"outfit":"robe","hair":"cropped","stance":"stand"})
	fig.player.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	var a=Acting.of(fig)
	a.active=false
	var probes:=_mesh_probe(fig.get(&"_parts"),fig.skeleton,4.0,[])
	_reset(fig,a)
	Acting.play(fig,clip,{"blend":0.0001})
	var length:=maxf(Acting.clip_length(clip),0.1)
	for frame in int(ceil(length/DT)):
		_frame(fig,a)
		if frame%10!=0:continue
		var pose:=_pose(fig.skeleton,false)
		for probe:Dictionary in probes:
			if probe.kind!="edges" or probe.name=="Body" or probe.name in STRETCH_SOFT:continue
			var p:=_skin(probe,pose)
			var best:=0.0;var edge:=-1
			for i in probe.rest.size():
				if probe.rest[i]<STRETCH_MIN_EDGE:continue
				var ratio:float=p[i*2].distance_to(p[i*2+1])/probe.rest[i]
				if ratio>best:best=ratio;edge=i
			if best<=STRETCH_MAX:continue
			print("CLOTHING_EDGE %s %s %.2fs %s x%.2f rest %s -> %s weights %s -> %s" % [variant,clip,frame*DT,probe.name,best,probe.verts[edge*2],probe.verts[edge*2+1],_edge_weights(probe,fig.skeleton,edge*2),_edge_weights(probe,fig.skeleton,edge*2+1)])
	fig.queue_free()
	await get_tree().process_frame
	get_tree().quit()

static func _edge_weights(probe:Dictionary,skel:Skeleton3D,i:int)->Dictionary:
	var result:={}
	for j in 4:
		var weight:float=probe.weights[i*4+j]
		if weight<0.001:continue
		var slot:int=probe.slots[i*4+j]
		var bone:int=probe.mat_bone[slot]
		result[skel.get_bone_name(bone) if bone>=0 else "none"]=snappedf(weight,0.001)
	return result
