extends RefCounted
## What a person becomes when the court puts them to death (figures, J).
## The engine decides who dies and the director how (court_executions);
## this only makes the bodies, out of the person's own merged figure
## (court_figure_merge.gd), so they keep their skin, hair, clothes and face:
##   split(fig, cut)  the body comes apart at the moment of the blow: "head",
##                    "limbs" (four limbs off, the head stays on), "all" (head
##                    and limbs), "halves" (sawn lengthwise, left and right).
##                    Each piece is a Node3D at its own middle (move, spin and
##                    drop it as you like), with red stump caps and a white bone
##                    end where it came off, and red flesh inside where it is
##                    open. A head (and each half) still blinks and rolls its
##                    eyes: piece.call("blink"), piece.call("look", "up").
##   bones(fig)       a clean skeleton in their place, moving as they moved.
##   char(fig)        soot-black with embers glowing; crumble(fig, 0..1) to ash.
##   rug(fig)         pressed flat on the floor; rug_roll(fig, 0..1) rolls it up.
##   bronze(fig)      a gleaming bronze statue, frozen as they stood.
##   freeze(fig)      holds the pose as it is now (clip, acting and gaze stop).
## Children never come apart, burn, flatten or turn to bronze: every call on
## a child does nothing and returns empty (the stage cuts away instead).
## prepare(fig) does the slow part (cutting the meshes by region, the bones)
## when an execution starts; nothing here runs per frame afterwards except
## the pose it keeps for the moment of the blow while prepared.
## Presentation only: nothing here reads or changes the game's state.

const Self:=preload("res://scripts/hud/court_figure_gore.gd")
const Merge:=preload("res://scripts/hud/court_figure_merge.gd")
const LIT:=preload("res://scripts/shaders/court_figure_lit.gdshader")

## Which bones each region of the body hangs from.
const REGION_OF_BONE:={"head":"head","jaw":"head","eye.L":"head","eye.R":"head","brow.L":"head","brow.R":"head",
	"upper_arm.L":"arm.L","forearm.L":"arm.L","hand.L":"arm.L","thumb.L":"arm.L","index.L":"arm.L","fingers.L":"arm.L",
	"upper_arm.R":"arm.R","forearm.R":"arm.R","hand.R":"arm.R","thumb.R":"arm.R","index.R":"arm.R","fingers.R":"arm.R",
	"thigh.L":"leg.L","shin.L":"leg.L","foot.L":"leg.L","toe.L":"leg.L","thigh.R":"leg.R","shin.R":"leg.R","foot.R":"leg.R","toe.R":"leg.R"}
## Where each region comes off (the bone at the cut).
const JOINT_OF:={"head":"head","arm.L":"upper_arm.L","arm.R":"upper_arm.R","leg.L":"thigh.L","leg.R":"thigh.R"}
## Slots that always go with the head (hair, beards, brows, the face's paint).
const HEAD_SLOTS:=["HAIR","HAIR_CARD","BROW","MOUTH","STUBBLE","EYES","IRIS","PUPIL","EYE_SHINE","EYE_WHITE"]
const FLESH:=Color(0.62,0.05,0.04)
const BONE_IVORY:=Color(0.93,0.88,0.76)

## Is this someone gore may be shown on (never a child)?
static func allowed(fig:Node3D)->bool:
	return fig!=null and is_instance_valid(fig) and String(fig.get("variant"))!="child" and fig.get("skeleton")!=null

# --- Prepared once an execution starts ----------------------------------------------

## Cuts their merged meshes by region (and by side, for the saw) and keeps
## their pose each frame for the moment of the blow. Safe to call twice.
static func prepare(fig:Node3D)->void:
	if not allowed(fig) or fig.has_meta(&"gore_prepared"):return
	var skel:Skeleton3D=fig.get("skeleton")
	var state:={"poses":[], "pieces":{}}
	fig.set_meta(&"gore_prepared",state)
	var keep:=func()->void:
		var poses:Array=state.poses
		poses.resize(skel.get_bone_count())
		for i in skel.get_bone_count():poses[i]=skel.get_bone_global_pose(i)
	skel.skeleton_updated.connect(keep)
	state["keep"]=keep
	keep.call()
	var merged:Dictionary=fig.get("_merged")
	for group in ["Body","Rest","Hair","Eyes"]:
		var node:=merged.get(group) as MeshInstance3D
		if node==null or not node.visible or node.mesh==null:continue
		state.pieces[group]=_cut(node,skel)

## Lets go of what prepare() kept (after the act, or if it never came).
static func release(fig:Node3D)->void:
	if fig==null or not fig.has_meta(&"gore_prepared"):return
	var state:Dictionary=fig.get_meta(&"gore_prepared")
	var skel:Skeleton3D=fig.get("skeleton")
	if skel!=null and state.has("keep") and skel.skeleton_updated.is_connected(state.keep):skel.skeleton_updated.disconnect(state.keep)
	fig.remove_meta(&"gore_prepared")

## One merged piece cut into regions: {region: {surface: {arrays, shapes}}},
## by the bone each vertex hangs from most (the head's slots always go with
## the head), and into "left"/"right" by which side of the body it is on.
static func _cut(node:MeshInstance3D,skel:Skeleton3D)->Dictionary:
	var mesh:ArrayMesh=node.mesh
	var skin:Skin=node.skin
	var bind_region:=PackedStringArray()
	for b in skin.get_bind_count():
		var name:=String(skin.get_bind_name(b))
		if name.is_empty() and skin.get_bind_bone(b)>=0:name=skel.get_bone_name(skin.get_bind_bone(b))
		bind_region.append(String(REGION_OF_BONE.get(name,"torso")))
	var out:={}
	var shape_names:=[]
	for i in mesh.get_blend_shape_count():shape_names.append(String(mesh.get_blend_shape_name(i)))
	for surface in mesh.get_surface_count():
		var arr:=mesh.surface_get_arrays(surface)
		var shapes:=mesh.surface_get_blend_shape_arrays(surface)
		var verts:PackedVector3Array=arr[Mesh.ARRAY_VERTEX]
		var bones:PackedInt32Array=arr[Mesh.ARRAY_BONES]
		var weights:PackedFloat32Array=arr[Mesh.ARRAY_WEIGHTS]
		var slots:Variant=arr[Mesh.ARRAY_CUSTOM0]
		var idx:PackedInt32Array=arr[Mesh.ARRAY_INDEX]
		var n:=verts.size()
		var region:=PackedStringArray();region.resize(n)
		var side:=PackedStringArray();side.resize(n)
		for v in n:
			var best:=0;var w:=-1.0
			for k in 4:
				if weights[v*4+k]>w:w=weights[v*4+k];best=bones[v*4+k]
			var r:=bind_region[best] if best<bind_region.size() else "torso"
			if slots is PackedFloat32Array:
				var slot:=int((slots as PackedFloat32Array)[v]+0.5)
				if slot<Merge.SLOTS.size() and String(Merge.SLOTS[slot]) in HEAD_SLOTS:r="head"
			region[v]=r
			side[v]="left" if verts[v].x>=0.0 else "right"
		# triangles by the region most of their corners are in
		var tri_region:={}
		for t in idx.size()/3:
			var a:=idx[t*3];var b:=idx[t*3+1];var c:=idx[t*3+2]
			var r:=region[a] if region[a]==region[b] or region[a]==region[c] else region[b]
			# (packed arrays are values: take the list out, add, put it back)
			var list:PackedInt32Array=tri_region.get(r,PackedInt32Array())
			list.append(a);list.append(b);list.append(c)
			tri_region[r]=list
			var s2:="left" if (verts[a].x+verts[b].x+verts[c].x)>=0.0 else "right"
			var side_list:PackedInt32Array=tri_region.get(s2,PackedInt32Array())
			side_list.append(a);side_list.append(b);side_list.append(c)
			tri_region[s2]=side_list
		for r:String in tri_region:
			var keep_shapes:=r in ["head","left","right"]
			var made:=_subset(arr,shapes if keep_shapes else [],tri_region[r])
			(out.get_or_add(r,{}) as Dictionary)[surface]=made
	out["_shape_names"]=shape_names
	return out

## The arrays of just these triangles (their vertices renumbered).
static func _subset(arr:Array,shapes:Array,tris:PackedInt32Array)->Dictionary:
	var remap:={}
	var order:=PackedInt32Array()
	var new_idx:=PackedInt32Array();new_idx.resize(tris.size())
	for i in tris.size():
		var v:=tris[i]
		var at:int=remap.get(v,-1)
		if at<0:
			at=order.size();remap[v]=at;order.append(v)
		new_idx[i]=at
	var out:=[];out.resize(Mesh.ARRAY_MAX)
	var n:int=(arr[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
	for k in Mesh.ARRAY_MAX:
		var src:Variant=arr[k]
		if src==null or k==Mesh.ARRAY_INDEX:continue
		# each array's own stride (bones and weights 4, a custom channel as stored)
		var stride:=1
		if typeof(src) in [TYPE_PACKED_FLOAT32_ARRAY,TYPE_PACKED_INT32_ARRAY,TYPE_PACKED_FLOAT64_ARRAY,TYPE_PACKED_BYTE_ARRAY] and n>0:
			stride=maxi(1,src.size()/n)
		out[k]=_gather(src,order,stride)
	out[Mesh.ARRAY_INDEX]=new_idx
	var out_shapes:=[]
	for sh:Array in shapes:
		var s2:=[];s2.resize(Mesh.ARRAY_MAX)
		for k in [Mesh.ARRAY_VERTEX,Mesh.ARRAY_NORMAL]:
			if sh[k]!=null:s2[k]=_gather(sh[k],order,1)
		out_shapes.append(s2)
	return {"arrays":out,"shapes":out_shapes}

static func _gather(src:Variant,order:PackedInt32Array,stride:int)->Variant:
	match typeof(src):
		TYPE_PACKED_VECTOR3_ARRAY:
			var a:PackedVector3Array=src;var o:=PackedVector3Array();o.resize(order.size())
			for i in order.size():o[i]=a[order[i]]
			return o
		TYPE_PACKED_VECTOR2_ARRAY:
			var a:PackedVector2Array=src;var o:=PackedVector2Array();o.resize(order.size())
			for i in order.size():o[i]=a[order[i]]
			return o
		TYPE_PACKED_COLOR_ARRAY:
			var a:PackedColorArray=src;var o:=PackedColorArray();o.resize(order.size())
			for i in order.size():o[i]=a[order[i]]
			return o
		TYPE_PACKED_FLOAT32_ARRAY:
			var a:PackedFloat32Array=src;var o:=PackedFloat32Array();o.resize(order.size()*stride)
			for i in order.size():
				for k in stride:o[i*stride+k]=a[order[i]*stride+k]
			return o
		TYPE_PACKED_INT32_ARRAY:
			var a:PackedInt32Array=src;var o:=PackedInt32Array();o.resize(order.size()*stride)
			for i in order.size():
				for k in stride:o[i*stride+k]=a[order[i]*stride+k]
			return o
		TYPE_PACKED_BYTE_ARRAY:
			var a:PackedByteArray=src;var o:=PackedByteArray();o.resize(order.size()*stride)
			for i in order.size():
				for k in stride:o[i*stride+k]=a[order[i]*stride+k]
			return o
		TYPE_PACKED_FLOAT64_ARRAY:
			var a:PackedFloat64Array=src;var o:=PackedFloat64Array();o.resize(order.size()*stride)
			for i in order.size():
				for k in stride:o[i*stride+k]=a[order[i]*stride+k]
			return o
	return src

# --- The blow --------------------------------------------------------------------------

## The body comes apart now: {piece name: Node3D}. cut: "head", "limbs",
## "all" or "halves". The figure itself is hidden; the pieces stand where
## it stood, in its pose at this moment, added beside it (its parent).
static func split(fig:Node3D,cut:="head")->Dictionary:
	if not allowed(fig):return {}
	prepare(fig)
	var state:Dictionary=fig.get_meta(&"gore_prepared")
	var skel:Skeleton3D=fig.get("skeleton")
	var wanted:Array
	match cut:
		"halves":wanted=["left","right"]
		"limbs":wanted=["torso_head","arm.L","arm.R","leg.L","leg.R"]
		"all":wanted=["head","torso","arm.L","arm.R","leg.L","leg.R"]
		_:wanted=["head","torso_limbs"]
	var poses:Array=state.poses if not (state.poses as Array).is_empty() else []
	if poses.is_empty():
		for i in skel.get_bone_count():poses.append(skel.get_bone_global_pose(i))
	var holder:Node=fig.get_parent()
	var merged:Dictionary=fig.get("_merged")
	var out:={}
	for name:String in wanted:
		var regions:Array=_regions_of(name)
		var piece:=Node3D.new();piece.name="Piece_"+name
		holder.add_child(piece)
		# a skeleton of its own, in the pose of the blow (nothing moves it after)
		var own:=_skeleton_copy(skel,poses)
		piece.add_child(own)
		for group in ["Body","Rest","Hair","Eyes"]:
			if not (state.pieces as Dictionary).has(group):continue
			var cut_of:Dictionary=state.pieces[group]
			var source:=merged.get(group) as MeshInstance3D
			var mesh:=_mesh_for(cut_of,regions,source)
			if mesh==null:continue
			var mi:=MeshInstance3D.new();mi.name=group
			mi.mesh=mesh;mi.skin=source.skin
			own.add_child(mi)
			mi.skeleton=NodePath("..")
			mi.cast_shadow=source.cast_shadow
			var from:PackedInt32Array=mesh.get_meta(&"src_surfaces",PackedInt32Array())
			for s in mesh.get_surface_count():
				var mat:=source.get_surface_override_material(from[s] if s<from.size() else 0)
				mi.set_surface_override_material(s,_gore_material(mat) if group!="Eyes" else mat)
			_copy_weights(source,mi)
			for param in ["face_a","face_b","dim"]:
				var value:Variant=source.get_instance_shader_parameter(param)
				if value!=null:mi.set_instance_shader_parameter(param,value)
		# the piece's pivot is its own middle
		var world:=skel.global_transform
		var mid:=_middle(name,poses,skel)
		piece.global_transform=Transform3D(Basis(),world*mid)
		own.global_transform=world
		_caps(piece,name,poses,skel)
		piece.set_script(load("res://scripts/hud/court_figure_piece.gd"))
		out[name]=piece
	fig.visible=false
	fig.call("_vanish_for_gore")
	return out

static func _regions_of(name:String)->Array:
	match name:
		"torso_head":return ["torso","head"]
		"torso_limbs":return ["torso","arm.L","arm.R","leg.L","leg.R"]
	return [name]

## Where a piece turns about: the bone it hangs from (head, arm, leg), the
## chest for the trunk, the middle of the body for a half.
static func _middle(name:String,poses:Array,skel:Skeleton3D)->Vector3:
	var bone:=""
	match name:
		"head":bone="head"
		"arm.L":bone="forearm.L"
		"arm.R":bone="forearm.R"
		"leg.L":bone="shin.L"
		"leg.R":bone="shin.R"
		"left","right","torso","torso_head","torso_limbs":bone="spine"
	var i:=skel.find_bone(bone)
	if i<0:return Vector3.ZERO
	var at:Vector3=(poses[i] as Transform3D).origin
	if name=="head":at+=(poses[i] as Transform3D).basis.y.normalized()*0.11
	return at

static func _skeleton_copy(skel:Skeleton3D,poses:Array)->Skeleton3D:
	var own:=Skeleton3D.new();own.name="Skeleton"
	for i in skel.get_bone_count():
		own.add_bone(skel.get_bone_name(i))
	for i in skel.get_bone_count():
		own.set_bone_parent(i,skel.get_bone_parent(i))
		own.set_bone_rest(i,skel.get_bone_rest(i))
	for i in skel.get_bone_count():
		var parent:=skel.get_bone_parent(i)
		var g:Transform3D=poses[i]
		var local:=((poses[parent] as Transform3D).affine_inverse()*g) if parent>=0 else g
		own.set_bone_pose_position(i,local.origin)
		own.set_bone_pose_rotation(i,local.basis.get_rotation_quaternion())
		own.set_bone_pose_scale(i,local.basis.get_scale())
	return own

static func _mesh_for(cut_of:Dictionary,regions:Array,source:MeshInstance3D)->ArrayMesh:
	var mesh:=ArrayMesh.new()
	mesh.blend_shape_mode=Mesh.BLEND_SHAPE_MODE_NORMALIZED
	var names:Array=cut_of.get("_shape_names",[])
	var any_shapes:=false
	for r in regions:
		var by:Dictionary=cut_of.get(r,{})
		for s in by:
			if not (by[s].shapes as Array).is_empty():any_shapes=true
	if any_shapes:
		for n in names:mesh.add_blend_shape(StringName(n))
	var from:=PackedInt32Array()
	for s in source.mesh.get_surface_count():
		# the regions of this surface, joined
		var parts:=[]
		for r in regions:
			var by:Dictionary=cut_of.get(r,{})
			if by.has(s):parts.append(by[s])
		if parts.is_empty():continue
		var joined:=_join(parts,any_shapes,names.size())
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,joined.arrays,joined.shapes,{},Merge._flags())
		from.append(s)
	mesh.set_meta(&"src_surfaces",from)
	return mesh if mesh.get_surface_count()>0 else null

static func _join(parts:Array,with_shapes:bool,shape_count:int)->Dictionary:
	if parts.size()==1 and (not with_shapes or not ((parts[0] as Dictionary).shapes as Array).is_empty()):
		return parts[0]
	var arrays:=[];arrays.resize(Mesh.ARRAY_MAX)
	var shapes:=[]
	for k in shape_count:
		var s2:=[];s2.resize(Mesh.ARRAY_MAX);shapes.append(s2)
	var base:=0
	for p:Dictionary in parts:
		var a:Array=p.arrays
		var n:int=(a[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
		for k in Mesh.ARRAY_MAX:
			if a[k]==null:continue
			if k==Mesh.ARRAY_INDEX:
				var idx:PackedInt32Array=a[k]
				var moved:=PackedInt32Array();moved.resize(idx.size())
				for i in idx.size():moved[i]=idx[i]+base
				arrays[k]=moved if arrays[k]==null else (arrays[k] as PackedInt32Array)+moved
			else:
				arrays[k]=a[k] if arrays[k]==null else arrays[k]+a[k]
		if with_shapes:
			var ps:Array=p.shapes
			for k in shape_count:
				for c in [Mesh.ARRAY_VERTEX,Mesh.ARRAY_NORMAL]:
					var add:Variant=(ps[k] as Array)[c] if k<ps.size() else (a[c] if c<a.size() else null)
					if add==null:add=a[c]
					(shapes[k] as Array)[c]=add if (shapes[k] as Array)[c]==null else (shapes[k] as Array)[c]+add
		base+=n
	return {"arrays":arrays,"shapes":shapes if with_shapes else []}

static func _copy_weights(source:MeshInstance3D,made:MeshInstance3D)->void:
	for i in made.get_blend_shape_count():
		var n:StringName=made.mesh.get_blend_shape_name(i)
		var j:=source.find_blend_shape_by_name(n)
		if j>=0:made.set_blend_shape_value(i,source.get_blend_shape_value(j))

## A piece's material: the person's own, red and wet inside where cut open.
static func _gore_material(mat:Material)->Material:
	if not mat is ShaderMaterial:return mat
	var made:=(mat as ShaderMaterial).duplicate() as ShaderMaterial
	made.set_shader_parameter("gore_inside",1.0)
	return made

static var _cap_mat:StandardMaterial3D
static var _bone_mat:StandardMaterial3D

## The stumps: a red cap and a white bone end where the piece came off (on
## both sides of the cut), facing out of the piece.
static func _caps(piece:Node3D,name:String,poses:Array,skel:Skeleton3D)->void:
	if _cap_mat==null:
		_cap_mat=StandardMaterial3D.new();_cap_mat.albedo_color=FLESH;_cap_mat.roughness=0.35;_cap_mat.emission_enabled=true
		_cap_mat.emission=FLESH*0.25
		_bone_mat=StandardMaterial3D.new();_bone_mat.albedo_color=BONE_IVORY;_bone_mat.roughness=0.6
	var world:=skel.global_transform
	var k:=world.basis.get_scale().y
	var cuts:Array=[]
	match name:
		"head":cuts=[["head",1.0]]
		"arm.L","arm.R","leg.L","leg.R":cuts=[[JOINT_OF[name],1.0]]
		"torso":cuts=[["head",-1.0],["upper_arm.L",-1.0],["upper_arm.R",-1.0],["thigh.L",-1.0],["thigh.R",-1.0]]
		"torso_head":cuts=[["upper_arm.L",-1.0],["upper_arm.R",-1.0],["thigh.L",-1.0],["thigh.R",-1.0]]
		"torso_limbs":cuts=[["head",-1.0]]
	var radius:={"head":0.050,"upper_arm.L":0.042,"upper_arm.R":0.042,"thigh.L":0.066,"thigh.R":0.066}
	for c:Array in cuts:
		var bone:=skel.find_bone(String(c[0]))
		if bone<0:continue
		var g:Transform3D=poses[bone]
		var axis:=(world.basis*g.basis.y).normalized()*float(c[1])
		var at:=world*g.origin
		var r:=float(radius.get(String(c[0]),0.045))*k
		var cap:=MeshInstance3D.new();cap.name="Stump"
		var disc:=CylinderMesh.new();disc.top_radius=r;disc.bottom_radius=r*1.04;disc.height=0.010*k;disc.radial_segments=16
		cap.mesh=disc;cap.material_override=_cap_mat
		piece.add_child(cap)
		cap.global_transform=Transform3D(_basis_along(axis),at-axis*0.004*k)
		var stub:=MeshInstance3D.new();stub.name="BoneEnd"
		var b:=CylinderMesh.new();b.top_radius=r*0.30;b.bottom_radius=r*0.34;b.height=0.024*k;b.radial_segments=10
		stub.mesh=b;stub.material_override=_bone_mat
		piece.add_child(stub)
		stub.global_transform=Transform3D(_basis_along(axis),at+axis*0.002*k)

## A basis whose Y runs along a direction.
static func _basis_along(dir:Vector3)->Basis:
	var y:=dir.normalized()
	var x:=y.cross(Vector3.FORWARD) if absf(y.dot(Vector3.FORWARD))<0.9 else y.cross(Vector3.RIGHT)
	x=x.normalized()
	var z:=x.cross(y).normalized()
	return Basis(x,y,z)

# --- The other ends ------------------------------------------------------------------

## Holds the pose as it is now: the clip, the acting and the gaze stop.
static func freeze(fig:Node3D)->void:
	if not allowed(fig):return
	prepare(fig)
	var state:Dictionary=fig.get_meta(&"gore_prepared")
	var skel:Skeleton3D=fig.get("skeleton")
	var poses:Array=state.poses
	var player:AnimationPlayer=fig.get("player")
	if player!=null:player.pause()
	for m in skel.get_children():
		if m is SkeletonModifier3D:(m as SkeletonModifier3D).active=false
	if poses.size()==skel.get_bone_count():
		for i in skel.get_bone_count():
			var parent:=skel.get_bone_parent(i)
			var g:Transform3D=poses[i]
			var local:=((poses[parent] as Transform3D).affine_inverse()*g) if parent>=0 else g
			skel.set_bone_pose_position(i,local.origin)
			skel.set_bone_pose_rotation(i,local.basis.get_rotation_quaternion())
			skel.set_bone_pose_scale(i,local.basis.get_scale())
	release(fig)

## Sets a gore uniform on every material the person is drawn with now.
static func _set_all(fig:Node3D,param:String,value:float)->void:
	for node in (fig.get("_merged") as Dictionary).values():
		var mi:=node as MeshInstance3D
		if mi==null or not mi.visible or mi.mesh==null:continue
		for s in mi.mesh.get_surface_count():
			var mat:=mi.get_surface_override_material(s) as ShaderMaterial
			if mat==null:continue
			if not mat.has_meta(&"gore_own"):
				mat=mat.duplicate() as ShaderMaterial;mat.set_meta(&"gore_own",true)
				if mat.next_pass is ShaderMaterial:
					var ink:=(mat.next_pass as ShaderMaterial).duplicate() as ShaderMaterial
					ink.set_meta(&"inked",ink.get_shader_parameter("inked"))
					mat.next_pass=ink
				mi.set_surface_override_material(s,mat)
			mat.set_shader_parameter(param,value)
			if param in ["rug","crumble"] and mat.next_pass is ShaderMaterial:
				# no ink round a rug or a falling heap of ash
				(mat.next_pass as ShaderMaterial).set_shader_parameter("inked",0 if value>0.0 else (mat.next_pass as ShaderMaterial).get_meta(&"inked",0))

## Soot-black, embers glowing in the cracks (their eyes still blink, white).
static func char(fig:Node3D,on:=true)->void:
	if not allowed(fig):return
	_set_all(fig,"charred",1.0 if on else 0.0)

## Falls to ash from the top down (0 whole, 1 gone).
static func crumble(fig:Node3D,amount:float)->void:
	if not allowed(fig):return
	_set_all(fig,"rug_height",float(fig.get("body_height")))
	_set_all(fig,"crumble",clampf(amount,0.0,1.0))

## Pressed flat on the floor, lying on their back (the pose is let go).
static func rug(fig:Node3D,on:=true)->void:
	if not allowed(fig):return
	var skel:Skeleton3D=fig.get("skeleton")
	if on:
		var player:AnimationPlayer=fig.get("player")
		if player!=null:player.stop()
		for m in skel.get_children():
			if m is SkeletonModifier3D:(m as SkeletonModifier3D).active=false
		skel.reset_bone_poses()
	_set_all(fig,"rug_height",float(fig.get("body_height")))
	_set_all(fig,"rug",1.0 if on else 0.0)
	for node in (fig.get("_merged") as Dictionary).values():
		if node is MeshInstance3D:(node as MeshInstance3D).cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF if on else (node as MeshInstance3D).cast_shadow

## The rug rolled up from the feet (0 flat, 1 a roll).
static func rug_roll(fig:Node3D,amount:float)->void:
	if not allowed(fig):return
	_set_all(fig,"rug_roll",clampf(amount,0.0,1.0))

## A gleaming bronze statue, frozen as they stand now.
static func bronze(fig:Node3D,on:=true)->void:
	if not allowed(fig):return
	if on:freeze(fig)
	_set_all(fig,"bronze",1.0 if on else 0.0)
	var eyes:=(fig.get("_merged") as Dictionary).get("Eyes") as MeshInstance3D
	# a statue's eyes are bronze too: the whites and irises of the living go
	if eyes!=null:eyes.visible=not on

## A clean skeleton in their place: the bones, moving as they moved (it rides
## the same skeleton: it can stand up, shrug and fall in their clips).
static func bones(fig:Node3D,on:=true)->Node3D:
	if not allowed(fig):return null
	var skel:Skeleton3D=fig.get("skeleton")
	var made:=skel.get_node_or_null("Merged/Bones") as MeshInstance3D
	if made==null and on:
		var body:=(fig.get("_merged") as Dictionary).get("Body") as MeshInstance3D
		if body==null:return null
		made=MeshInstance3D.new();made.name="Bones"
		made.mesh=_bone_mesh(skel,body.skin,float(fig.get("body_height")))
		made.skin=body.skin
		body.get_parent().add_child(made)
		made.skeleton=NodePath("../..")
		var ivory:=ShaderMaterial.new();ivory.shader=LIT
		ivory.set_shader_parameter("albedo",BONE_IVORY);ivory.set_shader_parameter("band_soft",0.25);ivory.set_shader_parameter("rim_amount",0.25)
		var dark:=ShaderMaterial.new();dark.shader=LIT
		dark.set_shader_parameter("albedo",Color(0.08,0.05,0.04));dark.set_shader_parameter("flat_colour",true)
		made.set_surface_override_material(0,ivory)
		if made.mesh.get_surface_count()>1:made.set_surface_override_material(1,dark)
	for node in (fig.get("_merged") as Dictionary).values():
		if node is MeshInstance3D and node!=made:(node as MeshInstance3D).visible=not on
	if made!=null:made.visible=on
	return made

# --- The bones, made from the skeleton -------------------------------------------------

static func _bone_mesh(skel:Skeleton3D,skin:Skin,height:float)->ArrayMesh:
	var k:=height/1.72
	var bind_of:={}
	for b in skin.get_bind_count():bind_of[String(skin.get_bind_name(b))]=b
	var rest:=func(name:String)->Vector3:
		var i:=skel.find_bone(name)
		return skel.get_bone_global_rest(i).origin if i>=0 else Vector3.ZERO
	var ivory:=SurfaceTool.new();ivory.set_skin_weight_count(SurfaceTool.SKIN_4_WEIGHTS);ivory.begin(Mesh.PRIMITIVE_TRIANGLES)
	var dark:=SurfaceTool.new();dark.set_skin_weight_count(SurfaceTool.SKIN_4_WEIGHTS);dark.begin(Mesh.PRIMITIVE_TRIANGLES)
	var on:=func(name:String)->int:return int(bind_of.get(name,0))
	# long bones, with a knob at each end, as bones are drawn
	for side in [".L",".R"]:
		for pair in [["upper_arm","forearm",0.016],["forearm","hand",0.013],["thigh","shin",0.022],["shin","foot",0.018]]:
			var a:Vector3=rest.call(String(pair[0])+side);var b:Vector3=rest.call(String(pair[1])+side)
			_dogbone(ivory,a,b,float(pair[2])*k,on.call(String(pair[0])+side))
		# the collarbone
		_rod(ivory,rest.call("shoulder"+side),rest.call("upper_arm"+side),0.009*k,on.call("shoulder"+side))
		# the hand and fingers
		var hand:Vector3=rest.call("hand"+side)
		for f in ["index","fingers","thumb"]:
			var base:Vector3=rest.call(f+side)
			_rod(ivory,hand,base,0.008*k,on.call("hand"+side))
			_rod(ivory,base,base+(base-hand).normalized()*0.055*k,0.0055*k,on.call(f+side))
		# the foot
		var ankle:Vector3=rest.call("foot"+side);var toe:Vector3=rest.call("toe"+side)
		_ellipsoid(ivory,(ankle+toe)*0.5+Vector3(0,-0.02*k,0),Vector3(0.030,0.018,0.065)*k,on.call("foot"+side),Basis())
	# the spine: knuckles of bone from the hips to the skull
	var chain:=[rest.call("hips"),rest.call("spine"),rest.call("chest"),rest.call("neck"),rest.call("head")]
	var chain_bone:=["hips","spine","chest","neck","neck"]
	for i in chain.size()-1:
		for j in 4:
			var t:=float(j)/4.0
			var p:Vector3=(chain[i] as Vector3).lerp(chain[i+1],t)
			_ellipsoid(ivory,p+Vector3(0,0,-0.025*k),Vector3(0.020,0.012,0.018)*k,on.call(chain_bone[i]),Basis())
	# the ribs: hoops round the chest, open at the breastbone
	var chest:Vector3=rest.call("chest");var neck:Vector3=rest.call("neck")
	for r in 5:
		var y:=lerpf(chest.y-0.10*k,neck.y-0.06*k,float(r)/4.0)
		var wide:=lerpf(0.130,0.095,float(r)/4.0)*k
		_hoop(ivory,Vector3(chest.x,y,chest.z+0.010*k),wide,wide*0.78,0.0075*k,on.call("chest"))
	_rod(ivory,Vector3(chest.x,neck.y-0.05*k,chest.z+0.105*k),Vector3(chest.x,chest.y-0.08*k,chest.z+0.10*k),0.010*k,on.call("chest"))
	# the pelvis: two wings and a ring
	var hips:Vector3=rest.call("hips")
	for sd in [-1.0,1.0]:
		_ellipsoid(ivory,hips+Vector3(sd*0.075*k,0.015*k,-0.005*k),Vector3(0.050,0.045,0.020)*k,on.call("hips"),Basis(Vector3.UP,sd*0.5))
	_hoop(ivory,hips+Vector3(0,-0.045*k,0.01*k),0.060*k,0.045*k,0.012*k,on.call("hips"))
	# the skull: a dome, the jaw, dark sockets and nose, a row of teeth
	var head:Vector3=rest.call("head")
	var skull:=head+Vector3(0,0.105*k,0.012*k)
	_ellipsoid(ivory,skull,Vector3(0.080,0.090,0.092)*k,on.call("head"),Basis())
	_ellipsoid(ivory,head+Vector3(0,0.030*k,0.045*k),Vector3(0.058,0.034,0.050)*k,on.call("jaw"),Basis())
	for sd in [-1.0,1.0]:
		_ellipsoid(dark,skull+Vector3(sd*0.032*k,0.004*k,0.078*k),Vector3(0.023,0.024,0.014)*k,on.call("head"),Basis())
	_ellipsoid(dark,skull+Vector3(0,-0.032*k,0.086*k),Vector3(0.010,0.014,0.008)*k,on.call("head"),Basis())
	for t in 8:
		var x:=(float(t)-3.5)*0.0105*k
		_ellipsoid(ivory,skull+Vector3(x,-0.062*k,0.080*k),Vector3(0.0048,0.0085,0.004)*k,on.call("head"),Basis())
	_ellipsoid(dark,skull+Vector3(0,-0.063*k,0.075*k),Vector3(0.045,0.012,0.008)*k,on.call("head"),Basis())
	var mesh:=ArrayMesh.new()
	ivory.generate_normals();dark.generate_normals()
	ivory.commit(mesh)
	dark.commit(mesh)
	return mesh

static func _vert(st:SurfaceTool,p:Vector3,bone:int)->void:
	st.set_color(Color(0.95,0,0,1))
	st.set_bones(PackedInt32Array([bone,0,0,0]))
	st.set_weights(PackedFloat32Array([1.0,0.0,0.0,0.0]))
	st.add_vertex(p)

static func _ellipsoid(st:SurfaceTool,c:Vector3,r:Vector3,bone:int,turn:Basis)->void:
	var rings:=8;var segs:=12
	for i in rings:
		for j in segs:
			var q:=[]
			for d in [[0,0],[1,0],[1,1],[0,1]]:
				var th:=PI*float(i+d[0])/float(rings)
				var ph:=TAU*float(j+d[1])/float(segs)
				q.append(c+turn*Vector3(sin(th)*cos(ph)*r.x,cos(th)*r.y,sin(th)*sin(ph)*r.z))
			for idx in [0,1,2,0,2,3]:_vert(st,q[idx],bone)

static func _rod(st:SurfaceTool,a:Vector3,b:Vector3,r:float,bone:int)->void:
	var d:=b-a
	if d.length()<0.001:return
	var basis:=_basis_along(d)
	var segs:=10
	for j in segs:
		var p0:=TAU*float(j)/float(segs);var p1:=TAU*float(j+1)/float(segs)
		var o0:=basis.x*cos(p0)*r+basis.z*sin(p0)*r;var o1:=basis.x*cos(p1)*r+basis.z*sin(p1)*r
		for v in [a+o0,b+o0,b+o1,a+o0,b+o1,a+o1]:_vert(st,v,bone)

static func _dogbone(st:SurfaceTool,a:Vector3,b:Vector3,r:float,bone:int)->void:
	var d:=(b-a)
	if d.length()<0.001:return
	var along:=d.normalized()
	var side:=_basis_along(along).x
	_rod(st,a+along*r*1.2,b-along*r*1.2,r,bone)
	for end in [a+along*r*1.0,b-along*r*1.0]:
		for sd in [-1.0,1.0]:
			_ellipsoid(st,end+side*sd*r*0.75,Vector3(r*1.15,r*1.15,r*1.15),bone,Basis())

static func _hoop(st:SurfaceTool,c:Vector3,rx:float,rz:float,tube:float,bone:int)->void:
	var segs:=20
	for j in segs:
		# open at the front (+Z, where the breastbone holds them)
		var a0:=TAU*float(j)/float(segs);var a1:=TAU*float(j+1)/float(segs)
		if absf((a0+a1)*0.5-PI)<0.40:continue
		var p0:=c+Vector3(sin(a0)*rx,0,-cos(a0)*rz);var p1:=c+Vector3(sin(a1)*rx,0,-cos(a1)*rz)
		_rod(st,p0,p1,tube,bone)
