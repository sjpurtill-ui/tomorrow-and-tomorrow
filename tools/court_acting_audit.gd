extends Node
## The acting's pose audit (K): every clip of the library played on every body
## through the real acting layer (court_acting.gd, the same retargeting the
## game does), sampled about ten times a clip, and measured three ways:
##   joints  anatomical limits from the posed bones: each bone's twist about
##           its own length against its rest (the waist, the chest, the neck, a
##           thigh turned round on the hips, a shin on its thigh...), and a knee
##           or an elbow bent backwards;
##   mesh    the skinned mesh's edges (the body and the outfits' main pieces),
##           skinned on the CPU from the skeleton the way the GPU does, against
##           their length at rest: an edge stretched past STRETCH_MAX tears;
##   cover   skin an outfit hides (the game's shader discards it) paired with
##           the nearest cloth over it: if the pair drifts apart by more than
##           COVER_GAP, the cloth has left that skin and the body shows a hole
##           (the old woman's faint: thighs gone from under a skirt that stayed
##           behind, the shins looking cut off).
## A failure is printed with the clip, the body, the time and what broke.
## Headless:
##   godot --headless --path <worktree> res://tools/court_acting_audit.tscn [-- clip,clip|all body,body]
## Prints COURT_ACTING_AUDIT lines and exits 1 when anything fails.
## tests/test_court_acting.gd calls audit_body() on the clips most at risk.

const Figure3D:=preload("res://scripts/hud/court_figure_3d.gd")
const Acting:=preload("res://scripts/hud/court_acting.gd")
const DT:=1.0/30.0
const SAMPLES:=10
const STRETCH_MAX:=2.6        # an edge longer than this many times its rest length tears
const STRETCH_MAX_BODY:=3.2   # the skin: an arm over the head stretches the armpit about 3x (linear skinning)
const STRETCH_MIN_EDGE:=0.004 # metres: shorter edges are ignored (noise)
const KNEE_BACK_MAX:=0.025    # metres the knee may sit behind the hip-ankle line (a little give)
const ELBOW_BACK_MAX:=0.035
const EDGES_PER_MESH:=140
const EDGES_BODY:=700
const COVER_SAMPLES:=260
const COVER_POKE:=0.025       # metres hidden skin may stand out through its cloth (the shader hides it)...
const COVER_GAP:=0.12         # ...unless the cloth is this far off: then that skin is left bare (a hole)
const COVER_NEAR:=0.05        # skin farther than this from the cloth at rest is hidden by another piece
const MESH_PREFIX:=["Body","hide_wrap","hide_cape","tunic_body","robe_body","robe_mantle"]
const OUTFITS:=["hide","tunic","robe"]
## Coverage is encoded for the whole outfit. Feet under shoes and the waist
## under a belt must not be paired with a nearby skirt that moves differently.
## Capes/mantles deliberately lift away and never supply body coverage.
const WRAPS:={"hide":["hide_wrap","hide_footwraps","hide_cord"],
	"tunic":["tunic_body","tunic_shoes","tunic_belt"],
	"robe":["robe_body","robe_shoes","robe_sash"]}
## Pieces whose stretch is reported but not failed (a cape bound to the arms
## stretches with them by design: J's call).
const STRETCH_SOFT:=["hide_cape"]
## Degrees a bone may turn about its own length, against its rest.
const TWIST_MAX:={"spine":45.0,"chest":45.0,"neck":70.0,"head":80.0,"thigh":65.0,"shin":35.0,"foot":50.0,
	"upper_arm":120.0,"forearm":130.0,"hand":95.0}

func _ready()->void:
	var clips:=PackedStringArray()
	var bodies:=PackedStringArray(Figure3D.BODIES)
	var args:=OS.get_cmdline_user_args()
	if args.size()>0 and args[0]!="all":clips=PackedStringArray(args[0].split(","))
	if args.size()>1:bodies=PackedStringArray(args[1].split(","))
	var fails:=0
	var t0:=Time.get_ticks_msec()
	for v in bodies:
		var glb:=""
		if args.size()>2:glb=args[2].path_join("court_figure_%s.glb" % v)
		var report:=audit_body(self,String(v),clips,SAMPLES,1.0,OUTFITS,glb)
		for line:String in report.lines:print("COURT_ACTING_AUDIT ",line)
		fails+=int(report.fails)
		print("COURT_ACTING_AUDIT body %s clips %d samples %d fails %d worst_stretch %.2f (%s) worst_gap %.2f m (%s)" % [
			v,report.clips,report.samples,report.fails,report.worst,report.worst_at,report.worst_gap,report.worst_gap_at])
	print("COURT_ACTING_AUDIT done fails ",fails," in ",(Time.get_ticks_msec()-t0)/1000.0," s")
	get_tree().quit(1 if fails>0 else 0)

## One body: every clip it has (or those named), in each outfit's cover.
## Returns {lines, fails, clips, samples, worst, worst_at, worst_gap, worst_gap_at}.
## mesh_glb: measure the meshes of another build of this body (a figure .glb
## read as it is, never imported), skinned by the same posed skeleton.
static func audit_body(host:Node,variant:String,only:=PackedStringArray(),samples:=SAMPLES,scale:=1.0,outfits:=OUTFITS,mesh_glb:="")->Dictionary:
	var out:={"lines":[],"fails":0,"clips":0,"samples":0,"worst":0.0,"worst_at":"","worst_gap":0.0,"worst_gap_at":""}
	var fig:Node3D=Figure3D.new()
	fig.set_meta(&"person_name","audit "+variant)
	host.add_child(fig)
	if not fig.setup({"variant":variant,"outfit":"hide","hair":"cropped","stance":"stand"}):
		out.lines.append("%s: no figure" % variant);out.fails=1
		fig.queue_free();return out
	fig.player.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	var a=Acting.of(fig)
	a.active=false
	var skel:Skeleton3D=fig.skeleton
	var parts:Array=fig.get(&"_parts")
	var other:Node=null
	if not mesh_glb.is_empty():
		other=Acting.load_glb(mesh_glb)
		if other==null:
			out.lines.append("%s: cannot read %s" % [variant,mesh_glb]);out.fails=1
			fig.queue_free();return out
		parts=[]
		for n in other.find_children("*","MeshInstance3D",true,false):parts.append(n)
	var probes:=_mesh_probe(parts,skel,scale,outfits)
	if other!=null:other.free()
	var front:=(skel.global_transform.basis.inverse()*fig.global_transform.basis*Vector3(0,0,1)).normalized()
	var bones:=_bones(skel,front)
	var k:float=fig.body_height/1.72
	var names:Array=Acting.library(variant).keys()
	names.sort()
	for clip:String in names:
		if not only.is_empty() and not clip in only:continue
		if not Acting.has_clip(clip):continue
		out.clips+=1
		_reset(fig,a)
		var length:=maxf(Acting.clip_length(clip),0.1)
		Acting.play(fig,clip,{"blend":0.0001})
		var t:=0.0
		var next:=0
		while next<samples:
			var at:=length*float(next)/float(samples-1) if samples>1 else 0.0
			while t<at-0.0001:
				_frame(fig,a);t+=DT
			if t<DT*0.5:_frame(fig,a)
			out.samples+=1
			var bad:=_joints(skel,bones,k)
			var st:=_measure(skel,probes)
			if float(st.ratio)>float(out.worst):
				out.worst=st.ratio;out.worst_at="%s %.2fs %s" % [clip,t,st.mesh]
			if float(st.gap)>float(out.worst_gap):
				out.worst_gap=st.gap;out.worst_gap_at="%s %.2fs %s" % [clip,t,st.gap_at]
			if float(st.ratio)>(STRETCH_MAX_BODY if String(st.mesh)=="Body" else STRETCH_MAX):bad.append("mesh %s edge x%.1f" % [st.mesh,st.ratio])
			for kind:String in (st.gaps as Dictionary):
				if kind.ends_with("@"):continue
				if float(st.gaps[kind])>COVER_GAP*k:bad.append("skin left bare by the %s (%.0f cm off, at %s)" % [kind,float(st.gaps[kind])*100.0,String(st.gaps[kind+"@"])])
			out.soft=maxf(float(out.get("soft",0.0)),float(st.soft))
			if not bad.is_empty():
				out.fails+=1
				out.lines.append("FAIL %s %s t=%.2f: %s" % [variant,clip,t,", ".join(bad)])
			next+=1
	fig.queue_free()
	return out

static func _reset(fig:Node3D,a)->void:
	a.let_go(0.0001)
	for i in 3:_frame(fig,a)
	fig.position=Vector3.ZERO

static func _frame(fig:Node3D,a)->void:
	fig.skeleton.reset_bone_poses()
	fig.player.advance(DT)
	a.step(DT)

# --- the joints ---------------------------------------------------------------------

static func _bones(skel:Skeleton3D,figure_front:Vector3)->Dictionary:
	var b:={}
	for n in ["hips","spine","chest","neck","head","thigh.L","thigh.R","shin.L","shin.R","foot.L","foot.R",
			"upper_arm.L","upper_arm.R","forearm.L","forearm.R","hand.L","hand.R"]:
		b[n]=skel.find_bone(n)
	# each bone's front (the figure's front at rest) in the bone's own frame
	var front:={}
	for n:String in b:
		var i:int=b[n]
		if i<0:continue
		front[n]=skel.get_bone_global_rest(i).basis.inverse()*figure_front
	b["_front"]=front
	return b

static func _origin(skel:Skeleton3D,i:int)->Vector3:
	return skel.get_bone_global_pose(i).origin

static func _front(skel:Skeleton3D,b:Dictionary,n:String)->Vector3:
	return (skel.get_bone_global_pose(int(b[n])).basis*(b._front[n] as Vector3)).normalized()

## A bone's turn about its own length (twist) against its rest, in degrees:
## the swing-twist split of its local rotation (glTF bones run along +Y).
static func _twist(skel:Skeleton3D,i:int)->float:
	var d:=skel.get_bone_rest(i).basis.get_rotation_quaternion().inverse()*skel.get_bone_pose_rotation(i)
	var tw:=2.0*atan2(d.y,d.w)
	if tw>PI:tw-=TAU
	if tw<-PI:tw+=TAU
	return absf(rad_to_deg(tw))

static func _joints(skel:Skeleton3D,b:Dictionary,k:float)->Array:
	var bad:=[]
	for n:String in ["spine","chest","neck","head","thigh.L","thigh.R","shin.L","shin.R","foot.L","foot.R",
			"upper_arm.L","upper_arm.R","forearm.L","forearm.R","hand.L","hand.R"]:
		var i:int=b[n]
		if i<0:continue
		var tw:=_twist(skel,i)
		if tw>float(TWIST_MAX[n.get_slice(".",0)]):bad.append("%s twisted %.0f deg" % [n,tw])
	for s in ["L","R"]:
		var h:=_origin(skel,b["thigh."+s]);var kn:=_origin(skel,b["shin."+s]);var an:=_origin(skel,b["foot."+s])
		var line:=(an-h).normalized()
		var off:=(kn-h)-line*(kn-h).dot(line)
		var back:=-off.dot(_front(skel,b,"thigh."+s))
		if back>KNEE_BACK_MAX*k:bad.append("knee.%s bent backwards %.0f cm" % [s,back*100.0])
		var sh:=_origin(skel,b["upper_arm."+s]);var el:=_origin(skel,b["forearm."+s]);var wr:=_origin(skel,b["hand."+s])
		var arm:=(wr-sh).normalized()
		var eo:=(el-sh)-arm*(el-sh).dot(arm)
		var fwd:=eo.dot(_front(skel,b,"upper_arm."+s))
		if fwd>ELBOW_BACK_MAX*k:bad.append("elbow.%s bent backwards %.0f cm" % [s,fwd*100.0])
	return bad

# --- the mesh -------------------------------------------------------------------------

## A probe: pairs of vertices (from any skinned pieces) with up to four
## (matrix, weight) slots each; a matrix is a bone with the bind pose its piece
## was skinned with. kind "edges": the pairs are mesh edges; "cover": a hidden
## skin vertex and the nearest vertex of the cloth over it.
static func _new_probe(name:String,kind:String)->Dictionary:
	# built in plain Arrays (shared by reference), packed by _finish()
	return {"name":name,"kind":kind,"verts":[],"slots":[],"weights":[],"mat_bone":[],"mat_bind":[],"mat_key":{},"rest":PackedFloat32Array()}

static func _finish(probe:Dictionary)->void:
	probe.verts=PackedVector3Array(probe.verts);probe.slots=PackedInt32Array(probe.slots)
	probe.weights=PackedFloat32Array(probe.weights);probe.mat_bone=PackedInt32Array(probe.mat_bone)

static func _surface(mi:MeshInstance3D)->Dictionary:
	var vs:=PackedVector3Array();var bs:=PackedInt32Array();var ws:=PackedFloat32Array();var ids:=PackedInt32Array();var cs:=PackedColorArray()
	var ns:=PackedVector3Array()
	for sidx in mi.mesh.get_surface_count():
		var arr:=mi.mesh.surface_get_arrays(sidx)
		if arr[Mesh.ARRAY_BONES]==null or arr[Mesh.ARRAY_WEIGHTS]==null or arr[Mesh.ARRAY_INDEX]==null:continue
		var base:=vs.size()
		var v:PackedVector3Array=arr[Mesh.ARRAY_VERTEX]
		var b:=PackedInt32Array(arr[Mesh.ARRAY_BONES]);var w:=PackedFloat32Array(arr[Mesh.ARRAY_WEIGHTS])
		var per:=b.size()/maxi(v.size(),1)
		vs.append_array(v)
		for i in v.size():
			for j in 4:
				bs.append(b[i*per+j] if j<per else 0);ws.append(w[i*per+j] if j<per else 0.0)
		for i in PackedInt32Array(arr[Mesh.ARRAY_INDEX]):ids.append(base+i)
		if arr[Mesh.ARRAY_NORMAL]!=null:ns.append_array(PackedVector3Array(arr[Mesh.ARRAY_NORMAL]))
		else:
			for i in v.size():ns.append(Vector3.UP)
		if arr[Mesh.ARRAY_COLOR]!=null:cs.append_array(PackedColorArray(arr[Mesh.ARRAY_COLOR]))
		else:
			for i in v.size():cs.append(Color(1,1,1,1))
	return {"v":vs,"b":bs,"w":ws,"i":ids,"c":cs,"n":ns}

static func _add_vertex(probe:Dictionary,mi:MeshInstance3D,skel:Skeleton3D,surf:Dictionary,v:int)->void:
	(probe.verts as Array).append((surf.v as PackedVector3Array)[v])
	var skin:Skin=mi.skin
	for j in 4:
		var bi:int=(surf.b as PackedInt32Array)[v*4+j]
		var w:float=(surf.w as PackedFloat32Array)[v*4+j]
		var key:="%d:%d" % [mi.get_instance_id(),bi]
		if not (probe.mat_key as Dictionary).has(key):
			var bone:=-1
			var bind:=Transform3D.IDENTITY
			if bi<skin.get_bind_count():
				bone=skin.get_bind_bone(bi)
				# a mesh of another build binds to its own skeleton: by name onto ours
				var own:=mi.get_node_or_null(mi.skeleton) as Skeleton3D
				if own!=null and own!=skel and bone>=0:bone=skel.find_bone(own.get_bone_name(bone))
				if bone<0:bone=skel.find_bone(skin.get_bind_name(bi))
				bind=skin.get_bind_pose(bi)
			probe.mat_key[key]=(probe.mat_bone as Array).size()
			(probe.mat_bone as Array).append(bone)
			(probe.mat_bind as Array).append(bind)
		(probe.slots as Array).append(int(probe.mat_key[key]))
		(probe.weights as Array).append(w)

static func _pose(skel:Skeleton3D,rest:bool)->Array:
	var out:=[]
	for i in skel.get_bone_count():out.append(skel.get_bone_global_rest(i) if rest else skel.get_bone_global_pose(i))
	return out

static func _set_rest_lengths(probe:Dictionary,rest:Array)->void:
	_finish(probe)
	var p:=_skin(probe,rest)
	var rl:=PackedFloat32Array()
	if String(probe.kind)=="cover":
		probe.normals=PackedVector3Array(probe.normals)
		for i in range(0,p.size(),2):rl.append(_poke(probe,rest,p,i))
	else:
		for i in range(0,p.size(),2):rl.append(p[i].distance_to(p[i+1]))
	probe.rest=rl

## How far a hidden skin vertex (pair i) stands out through its cloth along the
## cloth's normal (negative: inside, under it).
static func _poke(probe:Dictionary,pose:Array,p:PackedVector3Array,i:int)->float:
	var cv:=i+1
	var slots:PackedInt32Array=probe.slots;var weights:PackedFloat32Array=probe.weights
	var best:=0;var bw:=-1.0
	for j in 4:
		if weights[cv*4+j]>bw:
			bw=weights[cv*4+j];best=slots[cv*4+j]
	var bone:int=(probe.mat_bone as PackedInt32Array)[best]
	var m:Transform3D=((pose[bone] as Transform3D)*((probe.mat_bind as Array)[best] as Transform3D)) if bone>=0 else Transform3D.IDENTITY
	var n:=(m.basis*(probe.normals as PackedVector3Array)[i/2]).normalized()
	return (p[i]-p[cv]).dot(n)

static func _mesh_probe(parts:Array,skel:Skeleton3D,scale:float,outfits:Array)->Array:
	var probes:=[]
	var rng:=RandomNumberGenerator.new();rng.seed=7
	var rest:=_pose(skel,true)
	var body:MeshInstance3D=null
	var pieces:={}
	for mi:MeshInstance3D in parts:
		if mi.mesh==null or mi.skin==null:continue
		var name:=String(mi.name)
		if name=="Body":body=mi
		for kind:String in outfits:
			# the cloth that wraps the body (a cape or mantle may lift off it)
			if name in (WRAPS.get(kind,[]) as Array):
				if not pieces.has(kind):pieces[kind]=[]
				(pieces[kind] as Array).append(mi)
		var keep:=false
		for p:String in MESH_PREFIX:
			if name.begins_with(p):keep=true
		if not keep:continue
		var surf:=_surface(mi)
		var ids:PackedInt32Array=surf.i
		if ids.is_empty():continue
		var probe:=_new_probe(name,"edges")
		var want:=int((EDGES_BODY if name=="Body" else EDGES_PER_MESH)*scale)
		var tris:=ids.size()/3
		for e in mini(want,tris):
			var tri:=rng.randi_range(0,tris-1);var c:=rng.randi_range(0,2)
			_add_vertex(probe,mi,skel,surf,ids[tri*3+c]);_add_vertex(probe,mi,skel,surf,ids[tri*3+(c+1)%3])
		_set_rest_lengths(probe,rest)
		probes.append(probe)
	# cover: skin each outfit hides, and the nearest cloth of that outfit
	if body!=null:
		var bs:=_surface(body)
		var col:PackedColorArray=bs.c
		var bverts:PackedVector3Array=bs.v
		for kind:String in pieces:
			var ch:=1 if kind=="hide" else (2 if kind=="tunic" else 3)
			var hidden:=PackedInt32Array()
			for i in col.size():
				var c:=col[i]
				if (c.g if ch==1 else (c.b if ch==2 else c.a))>0.5:hidden.append(i)
			if hidden.is_empty():continue
			var cloth:=[]
			for mi:MeshInstance3D in pieces[kind]:cloth.append([mi,_surface(mi)])
			var probe:=_new_probe(kind,"cover")
			probe.normals=[]
			for e in mini(int(COVER_SAMPLES*scale),hidden.size()):
				var bv:=hidden[rng.randi_range(0,hidden.size()-1)]
				var at:=bverts[bv]
				var best:=1e9;var best_i:=-1;var best_v:=-1
				for ci in cloth.size():
					var vv:PackedVector3Array=(cloth[ci][1] as Dictionary).v
					var nn:PackedVector3Array=(cloth[ci][1] as Dictionary).n
					for gi in vv.size():
						var d:=at.distance_squared_to(vv[gi])
						# the cloth's outer face over this skin (its normal points away from the skin)
						if d<best and (vv[gi]-at).dot(nn[gi])>0.0:
							best=d;best_i=ci;best_v=gi
				# only skin this cloth itself hides (feet are under shoes, not the skirt)
				if best_i<0 or best>COVER_NEAR*COVER_NEAR:continue
				_add_vertex(probe,body,skel,bs,bv)
				_add_vertex(probe,cloth[best_i][0],skel,cloth[best_i][1],best_v)
				(probe.normals as Array).append(((cloth[best_i][1] as Dictionary).n as PackedVector3Array)[best_v])
			_set_rest_lengths(probe,rest)
			probes.append(probe)
	return probes

static func _skin(probe:Dictionary,pose:Array)->PackedVector3Array:
	var verts:PackedVector3Array=probe.verts;var slots:PackedInt32Array=probe.slots;var weights:PackedFloat32Array=probe.weights
	var mat_bone:PackedInt32Array=probe.mat_bone;var mat_bind:Array=probe.mat_bind
	var mats:=[]
	mats.resize(mat_bone.size())
	for m in mat_bone.size():
		var bone:=mat_bone[m]
		mats[m]=((pose[bone] as Transform3D)*(mat_bind[m] as Transform3D)) if bone>=0 else Transform3D.IDENTITY
	var out:=PackedVector3Array();out.resize(verts.size())
	for v in verts.size():
		var acc:=Vector3.ZERO;var tw:=0.0
		for j in 4:
			var w:=weights[v*4+j]
			if w<=0.0001:continue
			acc+=((mats[slots[v*4+j]] as Transform3D)*verts[v])*w;tw+=w
		out[v]=acc/tw if tw>0.0 else verts[v]
	return out

static func _measure(skel:Skeleton3D,probes:Array)->Dictionary:
	var pose:=_pose(skel,false)
	var worst:=0.0;var at:=""
	var soft:=0.0
	var gaps:={}
	var gap:=0.0;var gap_at:=""
	for probe:Dictionary in probes:
		var p:=_skin(probe,pose)
		var rl:PackedFloat32Array=probe.rest
		if String(probe.kind)=="cover":
			var g_most:=0.0
			var g_bone:=""
			for i in rl.size():
				# bared: out past the cloth's face AND well away from it (a skin
				# just through the cloth is hidden by the shader and the cloth
				# still covers it; skin the cloth has left behind is a hole)
				var poke:=_poke(probe,pose,p,i*2)-maxf(rl[i],0.0)
				if poke<=COVER_POKE:continue
				var dd:=p[i*2].distance_to(p[i*2+1])
				if dd>g_most:
					g_most=dd
					var sl:PackedInt32Array=probe.slots;var ww:PackedFloat32Array=probe.weights
					var bi:=0;var bw:=-1.0
					for j in 4:
						if ww[i*2*4+j]>bw:
							bw=ww[i*2*4+j];bi=sl[i*2*4+j]
					var bone:int=(probe.mat_bone as PackedInt32Array)[bi]
					g_bone=skel.get_bone_name(bone) if bone>=0 else "?"
			gaps[String(probe.name)]=g_most
			gaps[String(probe.name)+"@"]=g_bone
			if g_most>gap:
				gap=g_most;gap_at=String(probe.name)
			continue
		var is_soft:=String(probe.name) in STRETCH_SOFT
		for i in rl.size():
			if rl[i]<STRETCH_MIN_EDGE:continue
			var r:=p[i*2].distance_to(p[i*2+1])/rl[i]
			if is_soft:soft=maxf(soft,r)
			elif r>worst:
				worst=r;at=String(probe.name)
	return {"ratio":worst,"mesh":at,"gap":gap,"gap_at":gap_at,"gaps":gaps,"soft":soft}
