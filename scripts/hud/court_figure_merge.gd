extends RefCounted
## One person as few pieces (figures, J). A figure's .glb holds every hair,
## beard, outfit and face part as its own mesh; shown as they are, a person
## is some fifteen skinned pieces, and the GPU skins and morphs each piece
## apart every frame (that, not their triangles, was most of the court's
## cost). In a lit court (court_set_3d.gd) the visible parts are merged into:
##   Body  the skin, brows, mouth, beard and the lid line; the morphs that
##         move (moods, expressions, visemes) and casts shadows
##   Rest  the outfit; casts shadows
##   Hair  the hair and its cards; no shadow (its shade on the brow reads as a band)
##   Eyes  the whites (they write the stencil) and the iris, pupil and catch
##         of light (they read it); the gaze and lid morphs
## The person's own face (face_* morphs) is baked into the vertices, so it
## costs nothing a frame. Each vertex carries its slot (CUSTOM0.r) and one
## material per figure (court_figure_uber.gdshader) colours every slot.
## Merged meshes are kept for the same look (a cache), so a person seen again
## is made at once. Presentation only.

const SLOTS:=["SKIN","HAIR","HAIR_CARD","BROW","MOUTH","STUBBLE","CLOTH_A","CLOTH_B","CLOTH_C","LEATHER","WOOD","CLAY","EYES","IRIS","PUPIL","EYE_SHINE","EYE_WHITE"]
const UBER:=preload("res://scripts/shaders/court_figure_uber.gdshader")
const UBER_INK:=preload("res://scripts/shaders/court_figure_uber_ink.gdshader")
## Slots drawn with an inked edge (the rest are hair, decals and the eyes).
const INKED:=["SKIN","CLOTH_A","CLOTH_B","CLOTH_C","LEATHER","WOOD","CLAY"]
const READ:=["IRIS","PUPIL","EYE_SHINE"]
const CACHE_LIMIT:=32
## Off for a run (tests, or to compare): figures stay as their parts.
static var enabled:=true
static var _cache:Dictionary={}
static var _order:Array=[]
static var _stencil:Dictionary={}

## The merged meshes for these parts: {group: ArrayMesh}. groups: {name:
## [[MeshInstance3D, surface, slot], ...]}; face: the person's face_* weights.
static func meshes(key:String,groups:Dictionary,face:Dictionary)->Dictionary:
	if _cache.has(key):
		_order.erase(key);_order.append(key)
		return _cache[key]
	var made:={}
	for group:String in groups:
		var parts:Array=groups[group]
		if parts.is_empty():continue
		if group=="Eyes":
			made[group]=_merge_eyes(parts,face)
		else:
			made[group]=_merge(parts,face,group=="Body")
	_cache[key]=made;_order.append(key)
	while _order.size()>CACHE_LIMIT:_cache.erase(_order.pop_front())
	return made

static func _merge(parts:Array,face:Dictionary,moving:bool)->ArrayMesh:
	var names:Array=_moving_names(parts) if moving else []
	var built:=_arrays(parts,face,names)
	var mesh:=ArrayMesh.new()
	mesh.blend_shape_mode=Mesh.BLEND_SHAPE_MODE_NORMALIZED
	for n:String in names:mesh.add_blend_shape(StringName(n))
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,built.arrays,built.shapes,{},_flags())
	return mesh

## The eyes: the whites in one surface, what shows through them in another.
static func _merge_eyes(parts:Array,face:Dictionary)->ArrayMesh:
	var whites:=parts.filter(func(p:Array)->bool:return String(p[2])=="EYE_WHITE")
	var seen:=parts.filter(func(p:Array)->bool:return String(p[2]) in READ)
	var names:=_moving_names(parts)
	var mesh:=ArrayMesh.new()
	mesh.blend_shape_mode=Mesh.BLEND_SHAPE_MODE_NORMALIZED
	for n:String in names:mesh.add_blend_shape(StringName(n))
	for list in [whites,seen]:
		if list.is_empty():continue
		var built:=_arrays(list,face,names)
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,built.arrays,built.shapes,{},_flags())
	return mesh

static func _flags()->int:
	return Mesh.ARRAY_CUSTOM_R_FLOAT<<Mesh.ARRAY_FORMAT_CUSTOM0_SHIFT

## The morphs that move (not the person's own face), in a fixed order.
static func _moving_names(parts:Array)->Array:
	var names:Array=[]
	for p:Array in parts:
		var mesh:Mesh=(p[0] as MeshInstance3D).mesh
		for i in mesh.get_blend_shape_count():
			var n:=String(mesh.get_blend_shape_name(i))
			if not n.begins_with("face_") and not n in names:names.append(n)
	names.sort()
	return names

static func _arrays(parts:Array,face:Dictionary,names:Array)->Dictionary:
	var V:=PackedVector3Array();var N:=PackedVector3Array();var C:=PackedColorArray()
	var UV:=PackedVector2Array();var UV2:=PackedVector2Array()
	var B:=PackedInt32Array();var W:=PackedFloat32Array();var S:=PackedFloat32Array();var I:=PackedInt32Array()
	var SV:Array=[];var SN:Array=[]
	for n in names:
		SV.append(PackedVector3Array());SN.append(PackedVector3Array())
	for p:Array in parts:
		var mi:MeshInstance3D=p[0];var s:int=p[1]
		var slot:=float(maxi(0,SLOTS.find(String(p[2]))))
		var mesh:Mesh=mi.mesh
		var arr:=mesh.surface_get_arrays(s)
		var v0:PackedVector3Array=arr[Mesh.ARRAY_VERTEX]
		var n0:PackedVector3Array=arr[Mesh.ARRAY_NORMAL]
		var count:=v0.size()
		var bshapes:=mesh.surface_get_blend_shape_arrays(s)
		# their own face, baked into the vertices
		var v:=v0
		var nn:=n0
		var moved:=PackedInt32Array()
		var delta:=PackedVector3Array()
		var normal_delta:=PackedVector3Array()
		var baked:=false
		for i in mesh.get_blend_shape_count():
			var nm:=String(mesh.get_blend_shape_name(i))
			if not nm.begins_with("face_") or i>=bshapes.size():continue
			var w:=clampf(float(face.get(nm.trim_prefix("face_"),0.0)),-1.0,1.0)
			if absf(w)<0.002:continue
			var sv:PackedVector3Array=bshapes[i][Mesh.ARRAY_VERTEX]
			if sv.size()!=count:continue
			if not baked:
				v=v0.duplicate();nn=n0.duplicate();baked=true
			var sn:Variant=bshapes[i][Mesh.ARRAY_NORMAL]
			var has_n:=sn is PackedVector3Array and (sn as PackedVector3Array).size()==count
			var snp:PackedVector3Array=sn if has_n else PackedVector3Array()
			for k in count:
				var d:=sv[k]-v0[k]
				if d.x!=0.0 or d.y!=0.0 or d.z!=0.0:
					v[k]+=d*w
				# An unmoved vertex still turns when its neighbours move.
				if has_n:nn[k]+=(snp[k]-n0[k])*w
		if baked:
			normal_delta.resize(count)
			for k in count:
				var d:=v[k]-v0[k]
				if d.x!=0.0 or d.y!=0.0 or d.z!=0.0:
					moved.append(k);delta.append(d)
				# Keep the authored weighted delta before normalizing the base:
				# every moving target needs the same person's face baked in.
				normal_delta[k]=nn[k]-n0[k]
				nn[k]=_unit_normal(nn[k],n0[k])
		var base:=V.size()
		V.append_array(v);N.append_array(nn)
		var col:Variant=arr[Mesh.ARRAY_COLOR]
		if col is PackedColorArray and (col as PackedColorArray).size()==count:C.append_array(col)
		else:
			var white:=PackedColorArray();white.resize(count);white.fill(Color(1,0,0,0));C.append_array(white)
		UV.append_array(_or_zero2(arr[Mesh.ARRAY_TEX_UV],count))
		UV2.append_array(_or_zero2(arr[Mesh.ARRAY_TEX_UV2],count))
		var bones:Variant=arr[Mesh.ARRAY_BONES];var weights:Variant=arr[Mesh.ARRAY_WEIGHTS]
		if bones is PackedInt32Array and (bones as PackedInt32Array).size()==count*4:
			B.append_array(bones);W.append_array(weights)
		else:
			var b:=PackedInt32Array();b.resize(count*4);b.fill(0)
			var w2:=PackedFloat32Array();w2.resize(count*4);w2.fill(0.0)
			for k in count:w2[k*4]=1.0
			B.append_array(b);W.append_array(w2)
		var slots:=PackedFloat32Array();slots.resize(count);slots.fill(slot);S.append_array(slots)
		var idx:PackedInt32Array=arr[Mesh.ARRAY_INDEX]
		for k in idx.size():I.append(idx[k]+base)
		# the moving morphs: where this part has them, else it stays put
		for j in names.size():
			var at:int=mesh.get_blend_shape_count()
			var found:=-1
			for i in at:
				if String(mesh.get_blend_shape_name(i))==String(names[j]):found=i;break
			# (packed arrays are values: take the list out, add, put it back)
			var list:PackedVector3Array=SV[j]
			var normals:PackedVector3Array=SN[j]
			if found<0 or found>=bshapes.size():
				list.append_array(v);SV[j]=list
				normals.append_array(nn);SN[j]=normals
				continue
			var t:PackedVector3Array=(bshapes[found][Mesh.ARRAY_VERTEX] as PackedVector3Array)
			var valid_vertices:=t.size()==count
			if t.size()!=count:
				push_warning("court figure merge: %s %s morph %s has %d of %d vertices" % [mi.name,String(p[2]),names[j],t.size(),count])
				t=v
			elif baked:
				t=t.duplicate()
				for m in moved.size():t[moved[m]]+=delta[m]
			list.append_array(t);SV[j]=list
			var target_normals:Variant=bshapes[found][Mesh.ARRAY_NORMAL]
			if valid_vertices and target_normals is PackedVector3Array and (target_normals as PackedVector3Array).size()==count:
				var tn:PackedVector3Array=target_normals
				for k in count:
					normals.append(_unit_normal(tn[k]+(normal_delta[k] if baked else Vector3.ZERO),nn[k]))
			else:
				normals.append_array(nn)
			SN[j]=normals
	var arrays:=[]
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX]=V;arrays[Mesh.ARRAY_NORMAL]=N;arrays[Mesh.ARRAY_COLOR]=C
	arrays[Mesh.ARRAY_TEX_UV]=UV;arrays[Mesh.ARRAY_TEX_UV2]=UV2
	arrays[Mesh.ARRAY_BONES]=B;arrays[Mesh.ARRAY_WEIGHTS]=W;arrays[Mesh.ARRAY_CUSTOM0]=S;arrays[Mesh.ARRAY_INDEX]=I
	var shapes:=[]
	for j in names.size():
		var sa:=[]
		sa.resize(Mesh.ARRAY_MAX)
		sa[Mesh.ARRAY_VERTEX]=SV[j];sa[Mesh.ARRAY_NORMAL]=SN[j]
		shapes.append(sa)
	return {"arrays":arrays,"shapes":shapes}

## Opposing weighted morphs can cancel a normal. Keep a usable direction.
static func _unit_normal(value:Vector3,fallback:Vector3)->Vector3:
	if value.is_finite() and value.length_squared()>0.000001:return value.normalized()
	if fallback.is_finite() and fallback.length_squared()>0.000001:return fallback.normalized()
	return Vector3.UP

static func _or_zero2(a:Variant,count:int)->PackedVector2Array:
	if a is PackedVector2Array and (a as PackedVector2Array).size()==count:return a
	var z:=PackedVector2Array();z.resize(count);z.fill(Vector2.ZERO)
	return z

# --- One material a figure -----------------------------------------------------

## The figure's materials: its colours (sRGB) by slot, its outfit's cover
## channel. stencil: "" (opaque), "write" (the whites), "read" (iris and pupil).
static func material(colours:Dictionary,cover:int,key_dir:Vector3,stencil:="")->ShaderMaterial:
	var made:=ShaderMaterial.new()
	made.shader=_shader(stencil)
	var albedo:=PackedVector3Array();var a:=PackedVector4Array();var b:=PackedVector4Array();var c:=PackedVector4Array()
	for slot:String in SLOTS:
		# (as the parts' shader takes its albedo: the colour as given)
		var col:=Color(colours.get(slot,Color("8a7a66")))
		albedo.append(Vector3(col.r,col.g,col.b))
		var p:=_params(slot)
		a.append(p[0]);b.append(p[1]);c.append(p[2])
	made.set_shader_parameter("slot_albedo",albedo)
	made.set_shader_parameter("slot_a",a)
	made.set_shader_parameter("slot_b",b)
	made.set_shader_parameter("slot_c",c)
	made.set_shader_parameter("cover_channel",cover)
	made.set_shader_parameter("key_dir",key_dir)
	if stencil.is_empty():
		var ink:=ShaderMaterial.new();ink.shader=UBER_INK
		var mask:=0
		for slot in INKED:mask|=1<<SLOTS.find(slot)
		ink.set_shader_parameter("inked",mask)
		ink.set_shader_parameter("cover_channel",cover)
		made.next_pass=ink
	return made

## [band_soft, rim, strands, sheen], [grain, fill, stipple, card], [flat, skin, glow (shines of itself), -].
static func _params(slot:String)->Array:
	match slot:
		"SKIN":return [Vector4(0.34,0.14,0.0,0.0),Vector4(0.025,0.22,0.0,0.0),Vector4(0.0,1.0,0.0,0.0)]
		"HAIR":return [Vector4(0.30,0.22,0.24,0.22),Vector4(0.05,0.16,1.0,0.0),Vector4.ZERO]
		"HAIR_CARD":return [Vector4(0.30,0.30,0.0,0.18),Vector4(0.0,0.16,0.0,1.0),Vector4.ZERO]
		"STUBBLE":return [Vector4(0.10,0.14,0.0,0.0),Vector4(0.35,0.16,1.0,0.0),Vector4.ZERO]
		"EYE_SHINE":return [Vector4(0.10,0.0,0.0,0.0),Vector4(0.0,0.16,0.0,0.0),Vector4(1.0,0.0,0.9,0.0)]
		"EYE_WHITE":return [Vector4(0.10,0.0,0.0,0.0),Vector4(0.0,0.16,0.0,0.0),Vector4(1.0,0.0,0.22,0.0)]
		"MOUTH","EYES","IRIS","PUPIL":return [Vector4(0.10,0.0,0.0,0.0),Vector4(0.0,0.16,0.0,0.0),Vector4(1.0,0.0,0.0,0.0)]
	return [Vector4(0.10,0.14,0.0,0.0),Vector4(0.05,0.16,0.0,0.0),Vector4.ZERO]

static func _shader(stencil:String)->Shader:
	if stencil.is_empty():return UBER
	if _stencil.has(stencil):return _stencil[stencil]
	var code:=UBER.code
	if stencil=="write":
		code=code.replace("render_mode ","stencil_mode write, compare_always, 1;\nrender_mode ")
	else:
		code=code.replace("depth_draw_opaque","depth_draw_never").replace("render_mode ","stencil_mode read, compare_equal, 1;\nrender_mode blend_mix, shadows_disabled, ")
		code=code.replace("void fragment() {","void fragment() {\n\tALPHA = 1.0;")
	var made:=Shader.new();made.code=code
	_stencil[stencil]=made
	return made
