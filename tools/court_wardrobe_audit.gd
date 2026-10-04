extends Node
const Figure=preload("res://scripts/hud/court_figure_3d.gd")
const Acting=preload("res://scripts/hud/court_acting.gd")
const Audit=preload("res://tools/court_acting_audit.gd")
const Wardrobe=preload("res://scripts/hud/court_wardrobe.gd")

func _ready()->void:
	var failures:=0;var total:=0;var worst:=0.0;var gap:=0.0;var detail:Dictionary={}
	for variant:String in Figure.BODIES:
		for outfit:String in Wardrobe.OUTFITS:
			var f:=Figure.new();add_child(f)
			if not f.setup({"variant":variant,"outfit":outfit}):failures+=1;f.free();continue
			f.player.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
			var acting=Acting.of(f);acting.active=false
			var probes:=_probes(f,outfit)
			for clip:String in ["walk_in","walk_out","sit","sit_cross","kneel","bow"]:
				Audit._reset(f,acting)
				if clip in ["walk_in","walk_out","sit"]:f.play(clip,0,0)
				else:Acting.play(f,clip,{"blend":0.0})
				for sample in 8:
					for step in 5:Audit._frame(f,acting)
					var result:=Audit._measure(f.skeleton,probes)
					if float(result.ratio)>worst or float(result.gap)>gap:detail=_detail(f.skeleton,probes,detail,variant+" "+outfit+" "+clip+" t=%.2f"%[(sample+1)/6.0])
					total+=1;worst=maxf(worst,float(result.ratio));gap=maxf(gap,float(result.gap))
					if float(result.ratio)>Audit.STRETCH_MAX or float(result.gap)>Audit.COVER_GAP:
						failures+=1
						print("WARDROBE_MOTION FAIL %s %s %s t=%.2f stretch=%.2f (%s) gap=%.3f"%[variant,outfit,clip,(sample+1)/6.0,result.ratio,result.mesh,result.gap])
			f.free()
	print("WARDROBE_MOTION samples=%d failures=%d worst_stretch=%.2f gap=%.3f"%[total,failures,worst,gap])
	print("WARDROBE_MOTION_DETAIL ",detail)
	get_tree().quit(1 if failures else 0)

func _probes(f:Node3D,outfit:String)->Array:
	var probes:=[];var clothes:=[];var body:MeshInstance3D
	var rest:=Audit._pose(f.skeleton,true)
	for part:MeshInstance3D in f._parts:
		if String(part.name)=="Body":body=part
		if not String(part.name).begins_with(outfit+"_"):continue
		var surf:=Audit._surface(part)
		# Coverage is supplied by the fitted shells, not floating lapels, cuffs
		# or coat tails, whose nearest rest vertex can belong to another limb.
		if String(part.name).get_slice("_",1) in ["jacket","doublet","trousers","shoes"]:clothes.append([part,surf])
		var probe:=Audit._new_probe(String(part.name),"edges")
		var ids:PackedInt32Array=surf.i
		var step:=maxi(1,ids.size()/3/100)
		for triangle in range(0,ids.size()/3,step):
			for side in 3:
				Audit._add_vertex(probe,part,f.skeleton,surf,ids[triangle*3+side])
				Audit._add_vertex(probe,part,f.skeleton,surf,ids[triangle*3+(side+1)%3])
		Audit._set_rest_lengths(probe,rest);probes.append(probe)
	# The fitted shell copies the body's skin weights. On the inner thighs,
	# the other leg can be nearer in rest than the shell belonging to this leg.
	# Preserve the source correspondence; fall back to nearest geometry if a
	# future asset has no matching source weights (never skip that sample).
	var bindings:Dictionary={}
	for c in clothes.size():
		for j in clothes[c][1].v.size():
			var key:=_binding(clothes[c][1],j)
			if not bindings.has(key):bindings[key]=[]
			bindings[key].append(Vector2i(c,j))
	var bs:=Audit._surface(body);var colors:PackedColorArray=bs.c
	var cover:=Audit._new_probe(outfit,"cover");cover.normals=[]
	for i in range(0,colors.size(),maxi(1,colors.size()/220)):
		if colors[i].g<.5:continue
		var at:Vector3=bs.v[i];var distance:=INF;var chosen:=-1;var vertex:=-1
		for pair:Vector2i in bindings.get(_binding(bs,i),[]):
			var d:=at.distance_squared_to(clothes[pair.x][1].v[pair.y])
			if d<distance:distance=d;chosen=pair.x;vertex=pair.y
		if distance>.065*.065:
			distance=INF
			for c in clothes.size():
				var vertices:PackedVector3Array=clothes[c][1].v
				for j in vertices.size():
					var d:=at.distance_squared_to(vertices[j])
					if d<distance:distance=d;chosen=c;vertex=j
		if chosen<0:continue
		Audit._add_vertex(cover,body,f.skeleton,bs,i)
		Audit._add_vertex(cover,clothes[chosen][0],f.skeleton,clothes[chosen][1],vertex)
		cover.normals.append(clothes[chosen][1].n[vertex])
	Audit._set_rest_lengths(cover,rest);probes.append(cover)
	return probes

func _detail(skel:Skeleton3D,probes:Array,best:Dictionary,where:String)->Dictionary:
	var pose:=Audit._pose(skel,false)
	for probe:Dictionary in probes:
		var p:=Audit._skin(probe,pose)
		for i in probe.rest.size():
			if probe.kind=="cover":
				var poke:=Audit._poke(probe,pose,p,i*2)-maxf(probe.rest[i],0.0)
				var distance:=p[i*2].distance_to(p[i*2+1])
				if poke>Audit.COVER_POKE and distance>float(best.get("gap",0)):
					best.gap=distance;best.gap_where=where;best.gap_skin=probe.verts[i*2];best.gap_cloth=probe.verts[i*2+1]
			else:
				if probe.rest[i]<Audit.STRETCH_MIN_EDGE:continue
				var length:=p[i*2].distance_to(p[i*2+1]);var ratio:float=length/probe.rest[i]
				if ratio>float(best.get("ratio",0)):
					best.ratio=ratio;best.edge_where=where+" "+probe.name;best.rest_length=probe.rest[i];best.posed_length=length
					best.edge_a=probe.verts[i*2];best.edge_b=probe.verts[i*2+1]
	return best

func _binding(surface:Dictionary,vertex:int)->int:
	var bones:Array=[]
	for j in 4:
		var weight:=int(round(float(surface.w[vertex*4+j])*10000))
		if weight>0:bones.append(int(surface.b[vertex*4+j])*10001+weight)
	bones.sort();return hash(bones)
